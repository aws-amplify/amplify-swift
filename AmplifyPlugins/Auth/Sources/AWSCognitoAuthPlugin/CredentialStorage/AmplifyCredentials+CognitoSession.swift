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
        // TODO: Fix the errors:
        let error = AuthError.unknown("", nil)
        switch self {
        case .userPoolOnly(let tokens):
            return AWSAuthCognitoSession(isSignedIn: true,
                                         identityIdResult: .failure(error),
                                          awsCredentialsResult: .failure(error),
                                         cognitoTokensResult: .success(tokens))
        case .identityPoolOnly(let identityID, let credentials):
            return AWSAuthCognitoSession(isSignedIn: false,
                                         identityIdResult: .success(identityID),
                                          awsCredentialsResult: .success(credentials),
                                         cognitoTokensResult: .failure(error))
        case .identityPoolWithFederation(_, let identityID, let credentials):
            return AWSAuthCognitoSession(isSignedIn: false,
                                         identityIdResult: .success(identityID),
                                          awsCredentialsResult: .success(credentials),
                                         cognitoTokensResult: .failure(error))
        case .userPoolAndIdentityPool(let tokens, let identityID, let credentials):
            return AWSAuthCognitoSession(isSignedIn: false,
                                         identityIdResult: .success(identityID),
                                          awsCredentialsResult: .success(credentials),
                                         cognitoTokensResult: .success(tokens))
        case .noCredentials:
            return AWSAuthCognitoSession(isSignedIn: false,
                                         identityIdResult: .failure(error),
                                          awsCredentialsResult: .failure(error),
                                         cognitoTokensResult: .failure(error))
        }
    }
}
