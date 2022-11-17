//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import Foundation

extension AuthenticationState: Codable {

    enum CodingKeys: String, CodingKey {
        case type
        case signedInData
        case signedOutData
        case SignInState
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        if type == "AuthenticationState.SignedIn" {
            // TODO: Discuss with android team
            // let signedInData = try values.decode(SignedInData.self, forKey: .signedInData)
            self = .signedIn(.testData)
        } else if type == "AuthenticationState.SignedOut" {
            // TODO: Fix this
            // let signedOutData = try values.decode(SignedInData.self, forKey: .signedOutData)
            let signedOutData = SignedOutData(lastKnownUserName: nil)
            self = .signedOut(signedOutData)
        } else if type == "AuthenticationState.SigningIn" {
            self = .signingIn(try values.decode(SignInState.self, forKey: .SignInState))
        } else {
            fatalError("Decoding not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {

        switch self {
        default:
            fatalError("encoding not supported")
        }

    }
}
