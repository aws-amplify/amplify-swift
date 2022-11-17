//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import Foundation

extension AuthorizationState: Codable {

    enum CodingKeys: String, CodingKey {
        case type
        case amplifyCredential
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        if type == "AuthorizationState.SessionEstablished" {
            // TODO: Discuss with android team
            // let amplifyCredential = try values.decode(AmplifyCredentials.self, forKey: .amplifyCredential)
            self = .sessionEstablished(.testData)
        } else if type == "AuthorizationState.Configured" {
            self = .configured
        } else if type == "AuthorizationState.SigningIn" {
            self = .signingIn
        } else {
            fatalError("Decoding not supported")
        }

    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        default:
            fatalError()
        }
    }
}
