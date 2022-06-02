//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import SwiftUI

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
        return true
    }
}

struct FederatedToken {

    let token: String

    let provider: AuthProvider

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
