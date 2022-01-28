//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Amplify
import Foundation

@testable import AWSCognitoAuthPlugin

extension AWSAuthCognitoSession {
    static var testData: AWSAuthCognitoSession {
        AWSAuthCognitoSession(isSignedIn: true,
                              userSubResult: .failure(AuthError.unknown("", nil)),
                              identityIdResult: .success("identityId"),
                              awsCredentialsResult: .success(AuthAWSCognitoCredentials.testData),
                              cognitoTokensResult: .success(AWSCognitoUserPoolTokens.testData))
    }
}

extension AuthAWSCognitoCredentials {
    static var testData: AuthAWSCognitoCredentials {
        AuthAWSCognitoCredentials(accessKey: "accessKey",
                                  secretKey: "secretKey",
                                  sessionKey: "sessionKey",
                                  expiration: Date())
    }
}

extension CognitoCredentials {
    static var testData: CognitoCredentials {
        CognitoCredentials(userPoolTokens: AWSCognitoUserPoolTokens.testData,
                           identityId: "identityId",
                           awsCredential: AuthAWSCognitoCredentials.testData)
    }
}
