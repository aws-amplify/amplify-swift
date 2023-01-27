//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AmplifyCredentials {

    static let expiryBufferInSeconds = TimeInterval.seconds(2 * 60)
    
    var cognitoSession: AWSAuthCognitoSession {

        switch self {
        case .userPoolOnly(let signedInData):
            let identityError = AuthCognitoSignedInSessionHelper.identityIdErrorForInvalidConfiguration()
            let credentialsError = AuthCognitoSignedInSessionHelper.awsCredentialsErrorForInvalidConfiguration()
            return AWSAuthCognitoSession(
                isSignedIn: true,
                identityIdResult: .failure(identityError),
                awsCredentialsResult: .failure(credentialsError),
                cognitoTokensResult: .success(signedInData.cognitoUserPoolTokens))
        case .identityPoolOnly(let identityID, let credentials):
            return AuthCognitoSignedOutSessionHelper.makeSignedOutSession(
                identityId: identityID,
                awsCredentials: credentials)
        case .identityPoolWithFederation(_, let identityId, let awsCredentials):
            return AWSAuthCognitoSession(
                isSignedIn: true,
                identityIdResult: .success(identityId),
                awsCredentialsResult: .success(awsCredentials),
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
                awsCredentialsResult: .success(credentials),
                cognitoTokensResult: .success(signedInData.cognitoUserPoolTokens))
        case .noCredentials:
            return AuthCognitoSignedOutSessionHelper.makeSessionWithNoGuestAccess()
        }
    }

    func areValid() -> Bool {

        switch self {
            
        case .userPoolOnly(signedInData: let data):
            if data.cognitoUserPoolTokens.doesExpire(in: Self.expiryBufferInSeconds) {
                return false
            }

        case .identityPoolOnly(identityID: _, credentials: let awsCredentials):
            if awsCredentials.doesExpire(in: Self.expiryBufferInSeconds) {
                return false
            }

        case .userPoolAndIdentityPool(signedInData: let data,
                                      identityID: _,
                                      credentials: let awsCredentials):
            if  data.cognitoUserPoolTokens.doesExpire(in: Self.expiryBufferInSeconds) ||
                    awsCredentials.doesExpire(in: Self.expiryBufferInSeconds) {
                return false
            }

        case .identityPoolWithFederation(_, _, let awsCredentials):
            if awsCredentials.doesExpire() {
                return false
            }

        case .noCredentials:
            return false
        }
        return true
    }
}
