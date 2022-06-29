//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AmplifyCredentials {

    var cognitoSession: AWSAuthCognitoSession {

        switch self {
        case .userPoolOnly(let tokens):
            let identityError = AuthCognitoSignedInSessionHelper.identityIdErrorForInvalidConfiguration()
            let credentialsError = AuthCognitoSignedInSessionHelper.awsCredentialsErrorForInvalidConfiguration()
            return AWSAuthCognitoSession(isSignedIn: true,
                                         identityIdResult: .failure(identityError),
                                         awsCredentialsResult: .failure(credentialsError),
                                         cognitoTokensResult: .success(tokens))
        case .identityPoolOnly(let identityID, let credentials):
            return AuthCognitoSignedOutSessionHelper.makeSignedOutSession(
                identityId: identityID,
                awsCredentials: credentials)
        case .identityPoolWithFederation:
            // TODO: Not implemented
            fatalError("Add when implemented")
        case .userPoolAndIdentityPool(let tokens, let identityID, let credentials):
            return AWSAuthCognitoSession(isSignedIn: true,
                                         identityIdResult: .success(identityID),
                                         awsCredentialsResult: .success(credentials),
                                         cognitoTokensResult: .success(tokens))
        case .noCredentials:
            return AuthCognitoSignedOutSessionHelper.makeSessionWithNoGuestAccess()
        }
    }
}
