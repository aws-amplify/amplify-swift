//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

extension AWSPredictionsPlugin {
    @_spi(PredictionsFaceLiveness)
    public static func startFaceLivenessSession(
        withID sessionID: String,
        credentialsProvider: AWSCredentialsProvider? = nil,
        region: String,
        options: FaceLivenessSession.Options,
        completion: @escaping (Result<Void, FaceLivenessSessionError>) -> Void
    ) async throws -> FaceLivenessSession {

        let credential = try await credential(from: credentialsProvider)

        let signer = SigV4Signer(
            credential: .init(
                accessKey: credential.accessKey,
                secretKey: credential.secretKey,
                sessionToken: credential.sessionToken
            ),
            serviceName: "rekognition",
            region: region
        )

        let url = try streamingSessionURL(for: region)

        let session = FaceLivenessSession(
            websocket: WebSocketSession(),
            signer: signer,
            baseURL: url
        )

        session.onServiceException = { completion(.failure($0)) }

        return session
    }
}

extension FaceLivenessSession {
    @_spi(PredictionsFaceLiveness)
    public struct Options {
        public init() {}
    }
}

@_spi(PredictionsFaceLiveness)
public struct FaceLivenessSessionError: Swift.Error, Equatable {
    public let code: UInt8

    public static let unknown = Self(code: 0)
    public static let validation = Self(code: 1)
    public static let internalServer = Self(code: 2)
    public static let throttling = Self(code: 3)
    public static let serviceQuotaExceeded = Self(code: 4)
    public static let serviceUnavailable = Self(code: 5)
    public static let sessionNotFound = Self(code: 6)
    public static let accessDenied = Self(code: 7)
    public static let invalidRegion = Self(code: 8)
    public static let invalidURL = Self(code: 9)
}

extension FaceLivenessSessionError {
    init(event: LivenessEventKind.Exception) {
        switch event {
        case .accessDenied:
            self = .accessDenied
        case .validation:
            self = .validation
        case .internalServer:
            self = .internalServer
        case .throttling:
            self = .throttling
        case .serviceQuotaExceeded:
            self = .serviceQuotaExceeded
        case .serviceUnavailable:
            self = .serviceUnavailable
        case .sessionNotFound:
            self = .sessionNotFound
        default:
            self = .unknown
        }
    }
}

