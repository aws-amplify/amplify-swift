//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

/**
 WebSocketClient wraps URLSessionWebSocketTask and offers
 an abstraction of the data stream in the form of WebSocketEvent.
 */
@_spi(WebSocket)
public final actor WebSocketClient: NSObject {
    public enum Error: Swift.Error {
        case connectionLost
        case connectionCancelled
    }

    /// WebSocket server endpoint
    private let url: URL
    /// Additional Header for WebSocket handshake http request
    private let handshakeHttpHeaders: [String: String]
    /// Interceptor for appending additional info before makeing the connection
    private var interceptor: WebSocketInterceptor?
    /// Internal wriable WebSocketEvent data stream
    private nonisolated let subject = PassthroughSubject<WebSocketEvent, Never>()

    private let retryWithJitter = RetryWithJitter()

    /// Network monitor provide notification of device network status
    private let networkMonitor: WebSocketNetworkMonitorProtocol

    /// Cancellables bind with client life cycle
    private var cancelables = Set<AnyCancellable>()
    /// The underlying URLSessionWebSocketTask
    private var connection: URLSessionWebSocketTask? {
        willSet {
            connection?.cancel(with: .goingAway, reason: nil)
        }
    }

    /// A flag indicating whether to automatically update the connection upon network status updates
    private var autoConnectOnNetworkStatusChange: Bool
    /// A flag indicating whether to automatically retry on connection failure
    private var autoRetryOnConnectionFailure: Bool

    /// Interval between liveness probes while the socket is running.
    private let pingInterval: TimeInterval
    /// Timeout passed to the liveness probe.
    private let pingTimeout: TimeInterval
    /// Number of consecutive failed probes required before closing the connection.
    private let maxMissedPings: Int
    /// Liveness probe for a connection; overridable in tests. Defaults to a WebSocket ping/pong.
    private let isConnectionAlive: @Sendable (URLSessionWebSocketTask, TimeInterval) async -> Bool
    /// Count of consecutive failed probes for the current connection.
    private var missedPingCount: Int = 0
    /// The task running the periodic liveness-ping loop for the current connection.
    private var pingMonitorTask: Task<Void, Never>?
    /// Guards against overlapping recycles triggered by a failed liveness ping.
    private var isHandlingDeadConnection: Bool = false
    /// Data stream for downstream subscribers to engage with
    public var publisher: AnyPublisher<WebSocketEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    public var isConnected: Bool {
        connection?.state == .running
    }

    /**
     Creates a WebSocketClient.

     - Parameters:
        - url: WebSocket server endpoint
        - protocols: WebSocket subprotocols, for header `Sec-WebSocket-Protocol`
        - interceptor: An optional interceptor for additional info before establishing the connection
        - networkMonitor: Provides network status notifications
        - pingInterval: How often to run the liveness probe while the socket is running
        - pingTimeout: Timeout passed to the liveness probe
        - maxMissedPings: Consecutive failed probes before closing the socket with `.abnormalClosure`
        - isConnectionAlive: Probe used to test the socket; defaults to WebSocket ping/pong
     */
    public init(
        url: URL,
        handshakeHttpHeaders: [String: String] = [:],
        interceptor: WebSocketInterceptor? = nil,
        networkMonitor: WebSocketNetworkMonitorProtocol = AmplifyNetworkMonitor(),
        pingInterval: TimeInterval = 30,
        pingTimeout: TimeInterval = 5,
        maxMissedPings: Int = 2,
        isConnectionAlive: (@Sendable (URLSessionWebSocketTask, TimeInterval) async -> Bool)? = nil
    ) {
        self.url = url
        self.handshakeHttpHeaders = handshakeHttpHeaders
        self.interceptor = interceptor
        self.autoConnectOnNetworkStatusChange = false
        self.autoRetryOnConnectionFailure = false
        self.networkMonitor = networkMonitor
        self.pingInterval = pingInterval
        self.pingTimeout = pingTimeout
        self.maxMissedPings = maxMissedPings
        self.isConnectionAlive = isConnectionAlive ?? { await WebSocketClient.ping($0, timeout: $1) }
        super.init()
        /**
         The network monitor and retries should have a longer lifespan compared to the connection itself.
         This ensures that when the network goes offline or the connection drops,
         the network monitor can initiate a reconnection once the network is back online.
         */
        Task { await self.startNetworkMonitor() }
        Task { await self.retryOnConnectionFailure() }
    }

    deinit {
        self.subject.send(completion: .finished)
        self.autoConnectOnNetworkStatusChange = false
        self.autoRetryOnConnectionFailure = false
        cancelables = Set()
    }

    /**
     Connect to WebSocket server.
     - Parameters:
        - autoConnectOnNetworkStatusChange:
            A flag indicating whether this connection should be automatically updated when the network status changes.
        - autoRetryOnConnectionFailure:
            A flag indicating whether this connection should attampt to retry upon failure.
     */
    public func connect(
        autoConnectOnNetworkStatusChange: Bool = false,
        autoRetryOnConnectionFailure: Bool = false
    ) async {
        guard connection?.state != .running else {
            log.debug("[WebSocketClient] WebSocket is already in connecting state")
            return
        }

        log.debug("[WebSocketClient] WebSocket about to connect")
        self.autoConnectOnNetworkStatusChange = autoConnectOnNetworkStatusChange
        self.autoRetryOnConnectionFailure = autoRetryOnConnectionFailure

        await createConnectionAndRead()
    }

    /**
     Disconnect from WebSocket server.

     This will halt all automatic processes and attempt to gracefully close the connection.
     */
    public func disconnect() {
        guard connection?.state == .running else {
            log.debug("[WebSocketClient] client should be in connected state to trigger disconnect")
            return
        }

        autoConnectOnNetworkStatusChange = false
        autoRetryOnConnectionFailure = false
        stopPingMonitor()
        connection?.cancel(with: .goingAway, reason: nil)
    }

    /**
     Write text data to WebSocket server.
     - Parameters:
        - message: text message in String
     */
    public func write(message: String) async throws {
        log.debug("[WebSocketClient] WebSocket write message string: \(message)")
        try await connection?.send(.string(message))
    }

    /**
     Write binary data to WebSocket server.
     - Parameters:
        - message: binary message in Data
     */
    public func write(message: Data) async throws {
        log.debug("[WebSocketClient] WebSocket write message data: \(message)")
        try await connection?.send(.data(message))
    }

    private func createWebSocketConnection() async -> URLSessionWebSocketTask {
        let decoratedURL = await (interceptor?.interceptConnection(url: url)) ?? url
        var urlRequest = URLRequest(url: decoratedURL)
        handshakeHttpHeaders.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        urlRequest = await interceptor?.interceptConnection(request: urlRequest) ?? urlRequest

        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        return urlSession.webSocketTask(with: urlRequest)
    }

    private func createConnectionAndRead() async {
        log.debug("[WebSocketClient] Creating new connection and starting read")
        isHandlingDeadConnection = false
        missedPingCount = 0
        connection = await createWebSocketConnection()

        // Perform reading from a WebSocket in a separate task recursively to avoid blocking the execution.
        Task { await self.startReadMessage() }

        connection?.resume()

        // Detect a silently-dead socket (e.g. same-network TCP route swap) and recycle it.
        startPingMonitor()
    }

    /**
     Recusively read WebSocket data frames and publish to data stream.
     */
    private func startReadMessage() async {
        guard let connection else {
            log.debug("[WebSocketClient] WebSocket connection doesn't exist")
            return
        }

        if connection.state == .canceling || connection.state == .completed {
            log.debug("[WebSocketClient] WebSocket connection state is \(connection.state). Failed to read websocket message")
            return
        }

        do {
            let message = try await connection.receive()
            log.debug("[WebSocketClient] WebSocket received message: \(String(describing: message))")
            switch message {
            case .data(let data):
                subject.send(.data(data))
            case .string(let string):
                subject.send(.string(string))
            @unknown default:
                break
            }
        } catch {
            if connection.state == .running {
                subject.send(.error(error))
            } else {
                log.debug("[WebSocketClient] read message failed with connection state \(connection.state), error \(error)")
            }
        }

        await startReadMessage()
    }
}

// MARK: - URLSession delegate
extension WebSocketClient: URLSessionWebSocketDelegate {
    public nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        log.debug("[WebSocketClient] Websocket connected")
        subject.send(.connected)
    }

    public nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        log.debug("[WebSocketClient] Websocket disconnected")
        subject.send(.disconnected(closeCode, reason.flatMap { String(data: $0, encoding: .utf8) }))
        Task { await stopPingMonitor() }
    }

    public nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Swift.Error?
    ) {
        guard let error else {
            log.debug("[WebSocketClient] URLSession didComplete")
            return
        }

        log.debug("[WebSocketClient] URLSession didCompleteWithError: \(error))")

        let nsError = error as NSError
        switch (nsError.domain, nsError.code) {
        case (NSURLErrorDomain.self, NSURLErrorNetworkConnectionLost),
             (NSURLErrorDomain.self, NSURLErrorCannotConnectToHost),
             (NSURLErrorDomain.self, NSURLErrorNotConnectedToInternet),
             (NSPOSIXErrorDomain.self, Int(ECONNABORTED)),
             (NSPOSIXErrorDomain.self, 57):
            subject.send(.error(WebSocketClient.Error.connectionLost))
            Task { [weak self] in
                await self?.networkMonitor.updateState(.offline)
            }
        case (NSURLErrorDomain.self, NSURLErrorCancelled):
            log.debug("Skipping NSURLErrorCancelled error")
            subject.send(.error(WebSocketClient.Error.connectionCancelled))
        default:
            subject.send(.error(error))
        }
    }
}

// MARK: - network reachability
extension WebSocketClient {
    /// Monitor network status. Disconnect or reconnect when the network drops or comes back online.
    private func startNetworkMonitor() {
        networkMonitor.publisher.sink(receiveValue: { [weak self] stateChange in
            Task { [weak self] in
                await self?.onNetworkStateChange(stateChange)
            }
        })
        .store(in: &cancelables)
    }

    private func onNetworkStateChange(
        _ stateChange: (AmplifyNetworkMonitor.State, AmplifyNetworkMonitor.State)
    ) async {
        guard autoConnectOnNetworkStatusChange == true else {
            return
        }

        switch stateChange {
        case (.online, .offline):
            log.debug("[WebSocketClient] NetworkMonitor - Device went offline or network status became unknown")
            connection?.cancel(with: .invalid, reason: nil)
            subject.send(.disconnected(.invalid, nil))
        case (.offline, .online):
            log.debug("[WebSocketClient] NetworkMonitor - Device back online")
            await createConnectionAndRead()
        default:
            break
        }
    }
}

// MARK: - auto retry on connection failure
extension WebSocketClient {
    private func retryOnConnectionFailure() {
        subject.map { event -> URLSessionWebSocketTask.CloseCode? in
            guard case .disconnected(let closeCode, _) = event else {
                return nil
            }
            return closeCode
        }
        .compactMap { $0 }
        .sink(receiveCompletion: { _ in }) { [weak self] closeCode in
            Task { [weak self] in await self?.retryOnCloseCode(closeCode) }
        }
        .store(in: &cancelables)

        resetRetryCountOnConnected()
    }

    private func resetRetryCountOnConnected() {
        subject.filter {
            if case .connected = $0 {
                return true
            }
            return false
        }
        .sink(receiveCompletion: { _ in }) { [weak self] _ in
            Task { [weak self] in
                await self?.retryWithJitter.reset()
            }
        }
        .store(in: &cancelables)
    }

    private func retryOnCloseCode(_ closeCode: URLSessionWebSocketTask.CloseCode) async {
        guard autoRetryOnConnectionFailure == true else {
            return
        }

        switch closeCode {
        case .internalServerError,
             .abnormalClosure,
             .invalid,
             .policyViolation:
            log.debug("[WebSocketClient] Retrying on closeCode: \(closeCode)")
            let delayInMs = await retryWithJitter.next()
            Task { [weak self] in
                try await Task.sleep(nanoseconds: UInt64(delayInMs) * 1_000_000)
                await self?.createConnectionAndRead()
            }
        default:
            log.debug("[WebSocketClient] Not retrying for closeCode: \(closeCode)")
        }

    }
}

// MARK: - liveness ping monitor
extension WebSocketClient {
    /// Periodically probes the connection and recycles a dead socket via the existing retry path (not via `NWPathMonitor` events).
    private func startPingMonitor() {
        pingMonitorTask?.cancel()
        pingMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, await connection?.state == .running else { return }
                let nanoseconds = pingInterval * 1_000_000_000
                guard nanoseconds.isFinite,
                      nanoseconds >= 1,
                      nanoseconds <= Double(UInt64.max)
                else { return }
                try? await Task.sleep(nanoseconds: UInt64(nanoseconds))
                if Task.isCancelled {
                    return
                }
                await performLivenessCheck()
            }
        }
    }

    private func stopPingMonitor() {
        pingMonitorTask?.cancel()
        pingMonitorTask = nil
    }

    /// Closes the socket after `maxMissedPings` consecutive failed probes.
    private func performLivenessCheck() async {
        guard let connection, connection.state == .running else { return }

        let isAlive = await isConnectionAlive(connection, pingTimeout)
        // Discard the result if the socket was replaced or the monitor cancelled while probing.
        guard !Task.isCancelled, connection === self.connection else { return }
        if isAlive {
            missedPingCount = 0
            return
        }

        missedPingCount += 1
        log.debug("[WebSocketClient] Liveness ping missed (\(missedPingCount)/\(maxMissedPings))")
        guard missedPingCount >= maxMissedPings else { return }

        // Guard against overlapping recycles (reconnect storms).
        guard !isHandlingDeadConnection else { return }
        isHandlingDeadConnection = true

        log.debug("[WebSocketClient] \(missedPingCount) consecutive liveness pings failed — recycling dead connection")
        stopPingMonitor()
        subject.send(.error(WebSocketClient.Error.connectionLost))
        // abnormalClosure drives the existing retryOnCloseCode path via didCloseWith.
        connection.cancel(with: .abnormalClosure, reason: nil)
    }

    /// Sends one WebSocket ping; returns whether a pong arrived within `timeout` (single-resume race).
    private nonisolated static func ping(
        _ task: URLSessionWebSocketTask,
        timeout: TimeInterval
    ) async -> Bool {
        let resumed = AtomicValue(initialValue: false)
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            task.sendPing { error in
                if resumed.getAndSet(true) == false {
                    continuation.resume(returning: error == nil)
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if resumed.getAndSet(true) == false {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

extension WebSocketClient: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forNamespace: String(describing: self))
    }

    public nonisolated var log: Logger { Self.log }
}

extension WebSocketClient: Resettable {
    public func reset() async {
        subject.send(completion: .finished)
        autoConnectOnNetworkStatusChange = false
        autoRetryOnConnectionFailure = false
        stopPingMonitor()
        cancelables = Set()
    }
}
