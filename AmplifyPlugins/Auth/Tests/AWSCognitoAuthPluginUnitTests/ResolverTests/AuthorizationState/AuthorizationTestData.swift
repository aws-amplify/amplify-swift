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

    static var expiredTestData: AuthAWSCognitoCredentials {
        AuthAWSCognitoCredentials(accessKey: "accessKey",
                                  secretKey: "secretKey",
                                  sessionKey: "sessionKey",
                                  expiration: Date() - 10000)
    }
}

extension AmplifyCredentials {
    static var testData: AmplifyCredentials {
        AmplifyCredentials.userPoolAndIdentityPool(signedInData: .testData,
                                                   identityID: "identityId",
                                                   credentials: AuthAWSCognitoCredentials.testData)
    }

    static var testDataWithExpiredTokens: AmplifyCredentials {
        AmplifyCredentials.userPoolAndIdentityPool(signedInData: .expiredTestData,
                                                   identityID: "identityId",
                                                   credentials: AuthAWSCognitoCredentials.testData)
    }

    static var testDataWithExpiredAWSCredentials: AmplifyCredentials {
        AmplifyCredentials.userPoolAndIdentityPool(signedInData: .testData,
                                                   identityID: "identityId",
                                                   credentials: AuthAWSCognitoCredentials.expiredTestData)
    }

    static var testDataIdentityPoolWithExpiredTokens: AmplifyCredentials {
        AmplifyCredentials.identityPoolOnly(identityID: "identityId",
                                            credentials: AuthAWSCognitoCredentials.testData)
    }
}
