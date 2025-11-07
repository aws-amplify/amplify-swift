//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

@_spi(PredictionsFaceLiveness)
public final class FaceLivenessSession: LivenessService {
    let websocket: WebSocketSession
    let eventStreamEncoder: EventStream.Encoder
    let eventStreamDecoder: EventStream.Decoder
    let signer: SigV4Signer
    let baseURL: URL
    var serverEventListeners: [LivenessEventKind.Server: (FaceLivenessSession.SessionConfiguration) -> Void] = [:]
    var challengeTypeListeners: [LivenessEventKind.Server: (Challenge) -> Void] = [:]
    var onComplete: (ServerDisconnection) -> Void = { _ in }
    var serverDate: Date?
    var savedURLForReconnect: URL?
    var connectingState: ConnectingState = .normal

    enum ConnectingState {
        case normal
        case reconnect
    }

    private let livenessServiceDispatchQueue = DispatchQueue(
        label: "com.amazon.aws.amplify.liveness.service",
        qos: .userInteractive
    )

    init(
        websocket: WebSocketSession,
        signer: SigV4Signer,
        baseURL: URL
    ) {
        self.eventStreamEncoder = EventStream.Encoder()
        self.eventStreamDecoder = EventStream.Decoder()
        self.signer = signer
        self.baseURL = baseURL

        self.websocket = websocket

        websocket.onMessageReceived { [weak self] result in
            guard let receiveResult = self?.receive(result: result) else {
                self?.removeLivenessEventListeners()
                return .stopAndInvalidateSession
            }
            return receiveResult
        }

        websocket.onSocketClosed { [weak self] closeCode in
            self?.onComplete(.unexpectedClosure(closeCode))
            self?.removeLivenessEventListeners()
        }

        websocket.onServerDateReceived { [weak self] serverDate in
            self?.serverDate = serverDate
        }
    }
    
    deinit {
        Amplify.log.verbose("\(#fileID)-\(#function)")
    }

    public var onServiceException: (FaceLivenessSessionError) -> Void = { _ in }

    public func register(
        onComplete: @escaping (ServerDisconnection) -> Void
    ) {
        self.onComplete = onComplete
    }

    public func register(
        listener: @escaping (FaceLivenessSession.SessionConfiguration) -> Void,
        on event: LivenessEventKind.Server
    ) {
        serverEventListeners[event] = listener
    }

    public func register(listener: @escaping (Challenge) -> Void, on event: LivenessEventKind.Server) {
        challengeTypeListeners[event] = listener
    }

    public func closeSocket(with code: URLSessionWebSocketTask.CloseCode) {
        Amplify.log.verbose("\(#fileID)-\(#function): closeSocket with code: \(code)")
        livenessServiceDispatchQueue.async { [weak self] in
            self?.websocket.close(with: code)
        }
    }

    public func initializeLivenessStream(
        withSessionID sessionID: String,
        userAgent: String = "",
        challenges: [Challenge] = FaceLivenessSession.supportedChallenges,
        options: FaceLivenessSession.Options
    ) throws {
        Amplify.log.verbose("\(#fileID)-\(#function): Initialize liveness stream")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "session-id", value: sessionID),
            URLQueryItem(name: "precheck-view-enabled", value: options.preCheckViewEnabled ? "1" : "0"),
            URLQueryItem(name: "attempt-count", value: String(options.attemptCount)),
            URLQueryItem(
                name: "challenge-versions",
                value: challenges.map {$0.queryParameterString()}.joined(separator: ",")
            ),
            URLQueryItem(name: "video-width", value: "480"),
            URLQueryItem(name: "video-height", value: "640"),
            URLQueryItem(name: "x-amz-user-agent", value: userAgent)
        ]

        guard let url = components?.url
        else { throw FaceLivenessSessionError.invalidURL }

        savedURLForReconnect = url
        let signedConnectionURL = signer.sign(url: url)
        livenessServiceDispatchQueue.async { [weak self] in
            self?.websocket.open(url: signedConnectionURL)
        }
    }

    public func send(
        _ event: LivenessEvent<some Any>,
        eventDate: @escaping () -> Date = Date.init
    ) {
        Amplify.log.verbose("\(#fileID)-\(#function): Sending websocket event: \(event)")
        livenessServiceDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            let encodedPayload = self.eventStreamEncoder.encode(
                payload: event.payload,
                headers: [
                    ":content-type": .string("application/json"),
                    ":event-type": .string(event.eventTypeHeader),
                    ":message-type": .string("event")
                ]
            )

            let dateForSigning: Date
            if let serverDate = self.serverDate {
                dateForSigning = serverDate
            } else {
                dateForSigning = eventDate()
            }

            let signedPayload = self.signer.signWithPreviousSignature(
                payload: encodedPayload,
                dateHeader: (key: ":date", value: dateForSigning)
            )

            let encodedEvent = self.eventStreamEncoder.encode(
                payload: encodedPayload,
                headers: [
                    ":date": .timestamp(dateForSigning),
                    ":chunk-signature": .data(signedPayload)
                ]
            )

            self.websocket.send(
                message: .data(encodedEvent),
                onError: { error in
                    Amplify.log.verbose("\(#fileID)-\(#function): Error sending web socket message: \(error)")
                }
            )
        }
    }

    private func fallbackDecoding(_ message: EventStream.Message) -> WebSocketSession.WebSocketMessageResult {
        // Just in case the header value changes (it shouldn't)
        // We'll try to decode each of these events
        if let payload = try? JSONDecoder().decode(ServerSessionInformationEvent.self, from: message.payload) {
            Amplify.log.verbose("\(#fileID)-\(#function): Fallback decoding server session information: \(payload)")
            let sessionConfiguration = sessionConfiguration(from: payload)
            serverEventListeners[.challenge]?(sessionConfiguration)
        } else if let payload = try? JSONDecoder().decode(ChallengeEvent.self, from: message.payload) {
            Amplify.log.verbose("\(#fileID)-\(#function): Fallback decoding challenge: \(payload)")
            let challenge = challenge(from: payload)
            challengeTypeListeners[.challenge]?(challenge)
        } else if let payload = try? JSONDecoder().decode(DisconnectEvent.self, from: message.payload) {
            Amplify.log.verbose("\(#fileID)-\(#function): Fallback decoding disconnect: \(payload)")
            onComplete(.disconnectionEvent)
            removeLivenessEventListeners()
            return .stopAndInvalidateSession
        }
        return .continueToReceive
    }

    private func receive(result: Result<URLSessionWebSocketTask.Message, Error>) -> WebSocketSession.WebSocketMessageResult {
        switch result {
        case .success(.data(let data)):
            do {
                let message = try eventStreamDecoder.decode(data: data)

                if let eventType = message.headers.first(where: { $0.name == ":event-type" }) {
                    let serverEvent = LivenessEventKind.Server(rawValue: eventType.value)
                    Amplify.log.verbose("\(#fileID)-\(#function): Received server event: \(serverEvent)")
                    switch serverEvent {
                    case .challenge:
                        // :event-type ChallengeEvent
                        let payload = try JSONDecoder().decode(
                            ChallengeEvent.self, from: message.payload
                        )
                        let challenge = challenge(from: payload)
                        challengeTypeListeners[.challenge]?(challenge)
                        return .continueToReceive
                    case .sessionInformation:
                        // :event-type ServerSessionInformationEvent
                        let payload = try JSONDecoder().decode(
                            ServerSessionInformationEvent.self, from: message.payload
                        )
                        let sessionConfiguration = sessionConfiguration(from: payload)
                        serverEventListeners[.challenge]?(sessionConfiguration)
                        return .continueToReceive
                    case .disconnect:
                        // :event-type DisconnectionEvent
                        onComplete(.disconnectionEvent)
                        removeLivenessEventListeners()
                        return .stopAndInvalidateSession
                    default:
                        return .continueToReceive
                    }
                } else if let exceptionType = message.headers.first(where: { $0.name == ":exception-type" }) {
                    let exceptionEvent = LivenessEventKind.Exception(rawValue: exceptionType.value)
                    Amplify.log.verbose("\(#fileID)-\(#function): Received exception: \(exceptionEvent)")
                    guard exceptionEvent == .invalidSignature,
                          connectingState == .normal,
                          let savedURLForReconnect,
                          let serverDate else {
                        if let runtimeError = URLSessionWebSocketTask.CloseCode(rawValue: 4_005) {
                            Amplify.log.verbose("\(#fileID)-\(#function): Closing websocket with runtime error")
                            closeSocket(with: runtimeError)
                        }
                        onServiceException(.init(event: exceptionEvent))
                        removeLivenessEventListeners()
                        return .stopAndInvalidateSession
                    }

                    connectingState = .reconnect
                    let signedConnectionURL = signer.sign(
                        url: savedURLForReconnect,
                        date: { serverDate }
                    )
                    return .invalidateSessionAndRetry(url: signedConnectionURL)
                } else {
                    return fallbackDecoding(message)
                }
            } catch {
                Amplify.log.verbose("\(#fileID)-\(#function): Error decoding web socket message: \(error)")
                removeLivenessEventListeners()
                return .stopAndInvalidateSession
            }
        case .success:
            return .continueToReceive
        case .failure(let error):
            Amplify.log.verbose("\(#fileID)-\(#function): Failure result in web socket message: \(error)")
            removeLivenessEventListeners()
            return .stopAndInvalidateSession
        }
    }
    
    private func removeLivenessEventListeners() {
        serverEventListeners.removeAll()
        challengeTypeListeners.removeAll()
    }
}
