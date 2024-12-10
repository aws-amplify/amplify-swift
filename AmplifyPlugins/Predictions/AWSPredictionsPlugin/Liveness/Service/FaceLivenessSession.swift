//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

@_spi(PredictionsFaceLiveness)
public final class FaceLivenessSession: LivenessService {
    let websocket: WebSocketSession
    let eventStreamEncoder: EventStream.Encoder
    let eventStreamDecoder: EventStream.Decoder
    let signer: SigV4Signer
    let baseURL: URL
    var serverEventListeners: [LivenessEventKind.Server: (FaceLivenessSession.SessionConfiguration) -> Void] = [:]
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
        qos: .userInteractive)

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
            self?.receive(result: result) ?? .stopAndInvalidateSession
        }

        websocket.onSocketClosed { [weak self] closeCode in
            self?.onComplete(.unexpectedClosure(closeCode))
        }
        
        websocket.onServerDateReceived { [weak self] serverDate in
            self?.serverDate = serverDate
        }
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

    public func closeSocket(with code: URLSessionWebSocketTask.CloseCode) {
        livenessServiceDispatchQueue.async {
            self.websocket.close(with: code)
        }
    }

    public func initializeLivenessStream(withSessionID sessionID: String, userAgent: String = "") throws {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "session-id", value: sessionID),
            URLQueryItem(name: "challenge-versions", value: "FaceMovementAndLightChallenge_1.0.0"),
            URLQueryItem(name: "video-width", value: "480"),
            URLQueryItem(name: "video-height", value: "640"),
            URLQueryItem(name: "x-amz-user-agent", value: userAgent)
        ]

        guard let url = components?.url
        else { throw FaceLivenessSessionError.invalidURL }

        savedURLForReconnect = url
        let signedConnectionURL = signer.sign(url: url)
        livenessServiceDispatchQueue.async {
            self.websocket.open(url: signedConnectionURL)
        }
    }

    public func send<T>(
        _ event: LivenessEvent<T>,
        eventDate: @escaping () -> Date = Date.init
    ) {
        livenessServiceDispatchQueue.async {
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
                onError: { _ in }
            )
        }
    }

    private func fallbackDecoding(_ message: EventStream.Message) -> WebSocketSession.WebSocketMessageResult {
        // We only care about two events above.
        // Just in case the header value changes (it shouldn't)
        // We'll try to decode each of these events
        if let payload = try? JSONDecoder().decode(ServerSessionInformationEvent.self, from: message.payload) {
            let sessionConfiguration = sessionConfiguration(from: payload)
            self.serverEventListeners[.challenge]?(sessionConfiguration)
        } else if (try? JSONDecoder().decode(DisconnectEvent.self, from: message.payload)) != nil {
            onComplete(.disconnectionEvent)
            return .stopAndInvalidateSession
        }
        return .continueToReceive
    }

    private func receive(result: Result<URLSessionWebSocketTask.Message, Error>) -> WebSocketSession.WebSocketMessageResult {
        switch result {
        case .success(.data(let data)):
            do {
                let message = try self.eventStreamDecoder.decode(data: data)

                if let eventType = message.headers.first(where: { $0.name == ":event-type" }) {
                    let serverEvent = LivenessEventKind.Server(rawValue: eventType.value)
                    switch serverEvent {
                    case .challenge:
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
                        return .stopAndInvalidateSession
                    default:
                        return .continueToReceive
                    }
                } else if let exceptionType = message.headers.first(where: { $0.name == ":exception-type" }) {
                    let exceptionEvent = LivenessEventKind.Exception(rawValue: exceptionType.value)
                    Amplify.log.verbose("\(#function): Received exception: \(exceptionEvent)")
                    guard exceptionEvent == .invalidSignature,
                          connectingState == .normal,
                          let savedURLForReconnect = savedURLForReconnect,
                          let serverDate = serverDate else {
                        onServiceException(.init(event: exceptionEvent))
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
                return .stopAndInvalidateSession
            }
        case .success:
            return .continueToReceive
        case .failure:
            return .stopAndInvalidateSession
        }
    }
}
