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

    case userPoolOnly(tokens: AWSCognitoUserPoolTokens)

    case identityPoolOnly(identityID: String,
                          credentials: AuthAWSCognitoCredentials)

    case identityPoolWithFederation(federatedToken: FederatedToken,
                                    identityID: String,
                                    credentials: AuthAWSCognitoCredentials)

    case userPoolAndIdentityPool(tokens: AWSCognitoUserPoolTokens,
                                 identityID: String,
                                 credentials: AuthAWSCognitoCredentials)

    case noCredentials
}

extension AmplifyCredentials: Equatable {
    static func == (lhs: AmplifyCredentials, rhs: AmplifyCredentials) -> Bool {
        switch (lhs, rhs) {
        case (.userPoolOnly(let lhsToken), .userPoolOnly(let rhsToken)):
            return lhsToken == rhsToken

        case (.identityPoolOnly(let lhsIdentityId, let lhsCredentials),
              .identityPoolOnly(let rhsidentityId, let rhsCredentials)):
            return (lhsIdentityId == rhsidentityId) && (lhsCredentials == rhsCredentials)

        case (.userPoolAndIdentityPool(let lhsToken, let lhsIdentityId, let lhsCredentials),
              .userPoolAndIdentityPool(let rhsToken, let rhsidentityId, let rhsCredentials)):
            return (lhsToken == rhsToken) &&
            (lhsIdentityId == rhsidentityId) &&
            (lhsCredentials == rhsCredentials)

        case (.identityPoolWithFederation(federatedToken: let lhsToken,
                                          identityID: let lhsIdentityID,
                                          credentials: let lhsCredentials),
              .identityPoolWithFederation(federatedToken: let rhsToken,
                                          identityID: let rhsIdentityID,
                                          credentials: let rhsCredentials)):
            return (lhsToken == rhsToken) &&
            (lhsIdentityID == rhsIdentityID) &&
            (lhsCredentials == rhsCredentials)

        default: return false
        }
    }
}

struct FederatedToken {

    let token: String

    let provider: AuthProvider

}

extension FederatedToken: Equatable {
    static func == (lhs: FederatedToken, rhs: FederatedToken) -> Bool {
        guard lhs.token == rhs.token else {
            return false
        }
        switch (lhs.provider, rhs.provider) {

        case (.amazon, .amazon),
            (.apple, .apple),
            (.facebook, .facebook),
            (.google, .google),
            (.oidc, .oidc),
            (.saml, .saml):
            return true
        case (.custom(let lhsCustom), .custom(let rhsCustom)):
            return lhsCustom == rhsCustom
        default: return false
        }
    }
}

extension AmplifyCredentials {

    enum CodingKeys: String, CodingKey {
        case userPool
        case identityPool
        case federatedSignIn
    }

    enum IdentityPool: String, CodingKey {
        case identityId
        case awsCredentials
    }

    enum UserPool: String, CodingKey {
        case tokens
    }
}

extension AmplifyCredentials: Codable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let userPoolInfo = try? values.nestedContainer(keyedBy: UserPool.self, forKey: .userPool)
        let identityPoolInfo = try? values.nestedContainer(keyedBy: IdentityPool.self, forKey: .identityPool)

        if let userPoolInfo = userPoolInfo, let identityPoolInfo = identityPoolInfo {
            let tokens = try userPoolInfo.decode(AWSCognitoUserPoolTokens.self, forKey: .tokens)
            let identityID = try  identityPoolInfo.decode(String.self, forKey: .identityId)
            let credentials = try  identityPoolInfo.decode(AuthAWSCognitoCredentials.self, forKey: .awsCredentials)
            self = .userPoolAndIdentityPool(tokens: tokens, identityID: identityID, credentials: credentials)
            return
        }

        if  let identityPoolInfo = identityPoolInfo {
            let identityID = try  identityPoolInfo.decode(String.self, forKey: .identityId)
            let credentials = try  identityPoolInfo.decode(AuthAWSCognitoCredentials.self, forKey: .awsCredentials)
            self = .identityPoolOnly(identityID: identityID, credentials: credentials)
            return
        }

        if let userPoolInfo = userPoolInfo {
            let tokens = try userPoolInfo.decode(AWSCognitoUserPoolTokens.self, forKey: .tokens)
            self = .userPoolOnly(tokens: tokens)
            return
        }
        // TODO: Add when implemented for `identityPoolWithFederation`
        self = .noCredentials
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .userPoolOnly(let tokens):
            var userPool = container.nestedContainer(keyedBy: UserPool.self, forKey: .userPool)
            try userPool.encode(tokens, forKey: .tokens)
        case .identityPoolOnly(let identityID, let credentials):
            var identityPool = container.nestedContainer(keyedBy: IdentityPool.self, forKey: .identityPool)
            try identityPool.encode(identityID, forKey: .identityId)
            try identityPool.encode(credentials, forKey: .awsCredentials)

        case .identityPoolWithFederation:
            // TODO: Add when implemented
            fatalError("Not implemented")

        case .userPoolAndIdentityPool(let tokens, let identityID, let credentials):
            var userPool = container.nestedContainer(keyedBy: UserPool.self, forKey: .userPool)
            try userPool.encode(tokens, forKey: .tokens)

            var identityPool = container.nestedContainer(keyedBy: IdentityPool.self, forKey: .identityPool)
            try identityPool.encode(identityID, forKey: .identityId)
            try identityPool.encode(credentials, forKey: .awsCredentials)
        case .noCredentials: break
        }
    }

}

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

extension AmplifyCredentials {

    var areUserPoolTokenValid: Bool {
        //TODO: Fix the logic, reuse `areTokensExpiring`
        return false
    }

    var areAWSCredentialsValid: Bool {
        //TODO: Fix the logic, reuse `areTokensExpiring`
        return false
    }
}
