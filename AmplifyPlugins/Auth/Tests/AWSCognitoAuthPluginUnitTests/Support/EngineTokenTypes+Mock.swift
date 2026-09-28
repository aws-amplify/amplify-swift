//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable @preconcurrency import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

// Test data for the engine's token and credential forks. Each value is built exactly as the
// public type's test data of the same name (`Mocks/MockData/AWSCognitoUserPoolTokens+Mock.swift`,
// `ResolverTests/AuthorizationState/AuthorizationTestData.swift`), for tests that build engine state
// (`SignedInData`, `AmplifyCredentials`, events and states).

extension EngineUserPoolTokens {

    static var testData: EngineUserPoolTokens {
        let tokenData = [
            "sub": "1234567890",
            "username": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]
        return EngineUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            refreshToken: "refreshToken",
            expiresIn: Int(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        )
    }

    static let expiredTestData = EngineUserPoolTokens(
        idToken: "XX", accessToken: "XX", refreshToken: "XX", expiresIn: -10_000
    )

    static func testData(username: String, sub: String) -> EngineUserPoolTokens {
        let tokenData = [
            "sub": sub,
            "username": username,
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]
        return EngineUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            refreshToken: "refreshToken",
            expiresIn: 121
        )
    }

    static var testDataWithoutExp: EngineUserPoolTokens {
        let tokenDataWithoutExp = [
            "sub": "1234567890",
            "username": "John Doe",
            "iat": "1516239022"
        ]
        return EngineUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenDataWithoutExp),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenDataWithoutExp),
            refreshToken: "refreshToken",
            expiresIn: nil
        )
    }
}

extension EngineAWSCredentials {

    static var testData: EngineAWSCredentials {
        EngineAWSCredentials(
            accessKeyId: "accessKey",
            secretAccessKey: "secretAccessKey",
            sessionToken: "sessionToken",
            expiration: Date() + 121
        )
    }

    static var expiredTestData: EngineAWSCredentials {
        EngineAWSCredentials(
            accessKeyId: "accessKey",
            secretAccessKey: "secretAccessKey",
            sessionToken: "sessionToken",
            expiration: Date() - 10_000
        )
    }
}
