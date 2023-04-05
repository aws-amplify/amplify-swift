//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct LivenessEvent<T> {
    let payload: Data
    let eventKind: LivenessEventKind
    let eventTypeHeader: String
}

@_spi(PredictionsFaceLiveness)
public enum LivenessEventKind {
    public struct Server: Hashable {
        public static let challenge = Server()
        public static let disconnect = Server()
    }
    case server(Server)

    public struct Client: Equatable {
        let id: UInt8

        public static let initialFaceDetected = Client(id: 0)
        public static let video = Client(id: 1)
        public static let freshness = Client(id: 2)
        public static let final = Client(id: 3)
    }
    case client(Client)
}

extension LivenessEventKind: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .server(.challenge): return ".server(.challenge)"
        case .server(.disconnect): return ".server(.disconnect)"
        case .client(.initialFaceDetected): return ".client(.initialFaceDetected)"
        case .client(.video): return ".client(.video)"
        case .client(.freshness): return ".client(.freshness)"
        case .client(.final): return ".client(.final)"
        default: return "unknown"
        }
    }
}

extension LivenessEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
        LivenessEvent<\(T.self)>(
            payload: \(payload),
            eventKind: \(eventKind),
            eventTypeHeader: \(eventTypeHeader)
        )
        """
    }
}
