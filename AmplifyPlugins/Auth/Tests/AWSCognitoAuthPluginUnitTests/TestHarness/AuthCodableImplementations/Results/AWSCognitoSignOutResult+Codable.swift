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
        case revokeTokenError
        case hostedUIError
        case globalSignOutError
        case exception
        case refreshToken
        case accessToken
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if try values.decode(String.self, forKey: .signOutResult) == "COMPLETE" {
            self = .complete
        } else if try values.decode(String.self, forKey: .signOutResult) == "FAILED" {
            let error = try values.decode(AuthError.self, forKey: .error)
            self = .failed(error)
        } else if try values.decode(String.self, forKey: .signOutResult) == "PARTIAL" {

            let revokeTokenParent = try? values.nestedContainer(keyedBy: CodingKeys.self, forKey: .revokeTokenError)
            let revokeAuthError = try revokeTokenParent?.decodeIfPresent(AuthError.self, forKey: .exception)
            let refreshToken = try revokeTokenParent?.decodeIfPresent(String.self, forKey: .refreshToken)

            let globalSignOutError = try? values.nestedContainer(keyedBy: CodingKeys.self, forKey: .globalSignOutError)
            let globalAuthError = try globalSignOutError?.decodeIfPresent(AuthError.self, forKey: .exception)
            let accessToken = try globalSignOutError?.decodeIfPresent(String.self, forKey: .accessToken)

            var revokeTokenErrorObject: AWSCognitoRevokeTokenError? = nil
            if let revokeAuthError = revokeAuthError,
               let refreshToken = refreshToken {
                revokeTokenErrorObject = AWSCognitoRevokeTokenError(
                    refreshToken: refreshToken, error: revokeAuthError)
            }

            var globalSignOutErrorObject: AWSCognitoGlobalSignOutError? = nil
            if let globalAuthError = globalAuthError,
               let accessToken = accessToken {
                globalSignOutErrorObject = AWSCognitoGlobalSignOutError(
                    accessToken: accessToken, error: globalAuthError)
            }

            self = .partial(
                revokeTokenError: revokeTokenErrorObject,
                globalSignOutError: globalSignOutErrorObject,
                hostedUIError: nil)
        } else {
            fatalError("type not supported")
        }

    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }

}
