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

    public static let accessDenied = Self(code: 0)
    public static let invalidRegion = Self(code: 1)
    public static let invalidURL = Self(code: 2)
}

