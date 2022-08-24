//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Internal representation of Credentials Auth category maintain.
enum AmplifyCredentials {

    case userPoolOnly(signedInData: SignedInData)

    case identityPoolOnly(identityID: String,
                          credentials: AuthAWSCognitoCredentials)

    case identityPoolWithFederation(federatedToken: FederatedToken,
                                    identityID: String,
                                    credentials: AuthAWSCognitoCredentials)

    case userPoolAndIdentityPool(signedInData: SignedInData,
                                 identityID: String,
                                 credentials: AuthAWSCognitoCredentials)

    case noCredentials
}

extension AmplifyCredentials: Codable { }

extension AmplifyCredentials: Equatable { }

extension AmplifyCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {

        case .userPoolOnly:
            return "userPoolOnly"
        case .identityPoolOnly:
            return "identityPoolOnly"
        case .identityPoolWithFederation:
            return "identityPoolWithFederation"
        case .userPoolAndIdentityPool:
            return "userPoolAndIdentityPool"
        case .noCredentials:
            return "noCredentials"
        }
    }

}
