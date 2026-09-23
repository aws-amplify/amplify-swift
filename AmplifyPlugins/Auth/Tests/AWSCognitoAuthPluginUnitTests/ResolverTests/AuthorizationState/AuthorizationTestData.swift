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
        AWSAuthCognitoSession(
            isSignedIn: true,
            identityIdResult: .success("identityId"),
            awsCredentialsResult: .success(AuthAWSCognitoCredentials.testData),
            cognitoTokensResult: .success(AWSCognitoUserPoolTokens.testData)
        )
    }
}

extension AuthAWSCognitoCredentials {
    /// Common session-credential expiry for tests: comfortably beyond the refresh buffer
    /// (`AmplifyCredentials.expiryBufferInSeconds`, 120s) so scheduling jitter can't push the mocked
    /// session inside it and trigger a spurious credential refresh — which surfaced as a flaky
    /// "Service error occurred" (e.g. testFetchMFAPreferenceWithInternalErrorException). The prior
    /// `Date() + 121` sat 1s over the buffer.
    static let testExpiryInSeconds = AmplifyCredentials.expiryBufferInSeconds * 10

    static var testData: AuthAWSCognitoCredentials {
        AuthAWSCognitoCredentials(
            accessKeyId: "accessKey",
            secretAccessKey: "secretAccessKey",
            sessionToken: "sessionToken",
            expiration: Date().addingTimeInterval(testExpiryInSeconds)
        )
    }

    static var expiredTestData: AuthAWSCognitoCredentials {
        AuthAWSCognitoCredentials(
            accessKeyId: "accessKey",
            secretAccessKey: "secretAccessKey",
            sessionToken: "sessionToken",
            expiration: Date() - 10_000
        )
    }
}

extension FederatedToken {
    static var testData: FederatedToken {
        return  .init(token: "token", provider: .facebook)
    }
}

extension AmplifyCredentials {
    static var testData: AmplifyCredentials {
        AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: "identityId",
            credentials: AuthAWSCognitoCredentials.testData
        )
    }

    static var testDataIdentityPool: AmplifyCredentials {
        AmplifyCredentials.identityPoolOnly(
            identityID: "someId",
            credentials: .testData
        )
    }

    static var hostedUITestData: AmplifyCredentials {
        AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .hostedUISignInData,
            identityID: "identityId",
            credentials: AuthAWSCognitoCredentials.testData
        )
    }

    static var testDataWithExpiredTokens: AmplifyCredentials {
        AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .expiredTestData,
            identityID: "identityId",
            credentials: AuthAWSCognitoCredentials.testData
        )
    }

    static var testDataWithExpiredAWSCredentials: AmplifyCredentials {
        AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: "identityId",
            credentials: AuthAWSCognitoCredentials.expiredTestData
        )
    }

    static var testDataIdentityPoolWithExpiredTokens: AmplifyCredentials {
        AmplifyCredentials.identityPoolOnly(
            identityID: "identityId",
            credentials: AuthAWSCognitoCredentials.testData
        )
    }
}
