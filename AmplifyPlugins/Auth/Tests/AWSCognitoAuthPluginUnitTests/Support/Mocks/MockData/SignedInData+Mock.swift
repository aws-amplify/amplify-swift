//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

extension SignedInData {

    static var testData: SignedInData {
        let tokens = AWSCognitoUserPoolTokens.testData
        return SignedInData(signedInDate: Date(),
                            signInMethod: .apiBased(.userSRP),
                            cognitoUserPoolTokens: tokens)
    }

    static var expiredTestData: SignedInData {
        let tokens = AWSCognitoUserPoolTokens.expiredTestData
        return SignedInData(signedInDate: Date(),
                            signInMethod: .apiBased(.userSRP),
                            cognitoUserPoolTokens: tokens)
    }
}
