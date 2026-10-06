//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import InternalAWSCognitoAuth

extension AmplifyCredentials {
    // `expiryBufferInSeconds` is declared with the engine's `AmplifyCredentials`.
    var cognitoSession: AWSAuthCognitoSession {

        switch self {
        case .userPoolOnly(let signedInData):
            let identityError = AuthCognitoSignedInSessionHelper.identityIdErrorForInvalidConfiguration()
            let credentialsError = AuthCognitoSignedInSessionHelper.awsCredentialsErrorForInvalidConfiguration()
            return AWSAuthCognitoSession(
                isSignedIn: true,
                identityIdResult: .failure(identityError),
                awsCredentialsResult: .failure(credentialsError),
                cognitoTokensResult: .success(AWSCognitoUserPoolTokens(signedInData.cognitoUserPoolTokens))
            )
        case .identityPoolOnly(let identityID, let credentials):
            return AuthCognitoSignedOutSessionHelper.makeSignedOutSession(
                identityId: identityID,
                awsCredentials: AuthAWSCognitoCredentials(credentials)
            )
        case .identityPoolWithFederation(_, let identityId, let awsCredentials):
            return AWSAuthCognitoSession(
                isSignedIn: true,
                identityIdResult: .success(identityId),
                awsCredentialsResult: .success(AuthAWSCognitoCredentials(awsCredentials)),
                cognitoTokensResult: .failure(
                    .invalidState(
                        "Users Federated to Identity Pool do not have User Pool access.",
                        "To access User Pool data, you must use a Sign In method.",
                        nil
                    )
                )
            )
        case .userPoolAndIdentityPool(let signedInData, let identityID, let credentials):
            return AWSAuthCognitoSession(
                isSignedIn: true,
                identityIdResult: .success(identityID),
                awsCredentialsResult: .success(AuthAWSCognitoCredentials(credentials)),
                cognitoTokensResult: .success(AWSCognitoUserPoolTokens(signedInData.cognitoUserPoolTokens))
            )
        case .noCredentials:
            return AuthCognitoSignedOutSessionHelper.makeSessionWithNoGuestAccess()
        }
    }

    // `areValid(at:)` is declared with the engine's `AmplifyCredentials`.
}
