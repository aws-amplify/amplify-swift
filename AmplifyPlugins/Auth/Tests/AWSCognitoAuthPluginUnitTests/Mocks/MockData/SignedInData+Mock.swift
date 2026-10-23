//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

extension SignedInData {

    static var testData: SignedInData {
        let tokens = EngineUserPoolTokens.testData
        return SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: tokens
        )
    }

    static var expiredTestData: SignedInData {
        let tokens = EngineUserPoolTokens.expiredTestData
        return SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: tokens
        )
    }

    static var hostedUISignInData: SignedInData {
        let tokens = EngineUserPoolTokens.testData
        return SignedInData(
            signedInDate: Date(),
            signInMethod: .hostedUI(.init(
                scopes: [],
                providerInfo: .init(authProvider: .google, idpIdentifier: ""),
                presentationAnchor: nil,
                preferPrivateSession: false,
                nonce: nil,
                language: nil,
                loginHint: nil,
                prompt: nil,
                resource: nil
            )),
            cognitoUserPoolTokens: tokens
        )
    }
}
