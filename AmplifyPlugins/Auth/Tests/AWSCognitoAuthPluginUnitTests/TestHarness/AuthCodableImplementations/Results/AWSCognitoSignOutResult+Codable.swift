//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin
@testable import Amplify

extension AWSCognitoSignOutResult: Equatable {
    public static func == (lhs: AWSCognitoSignOutResult, rhs: AWSCognitoSignOutResult) -> Bool {
        switch (lhs, rhs) {

        case (.complete, .complete):
            return true

        case (.failed, .failed):
            return true

        case (.partial, .partial):
            return true

        default:
            return false
        }
    }

}

extension AWSCognitoSignOutResult: Codable {

    enum CodingKeys: String, CodingKey {
        case signOutResult
        case error
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if try values.decode(String.self, forKey: .signOutResult) == "COMPLETE" {
            self = .complete
        } else if try values.decode(String.self, forKey: .signOutResult) == "FAILED" {
            let error = try values.decode(AuthError.self, forKey: .error)
            self = .failed(error)
        } else if try values.decode(String.self, forKey: .signOutResult) == "PARTIAL" {
            fatalError("decode associated types")
            self = .partial(
                revokeTokenError: nil,
                globalSignOutError: nil,
                hostedUIError: nil)
        } else {
            fatalError("type not supported")
        }

    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }

}
