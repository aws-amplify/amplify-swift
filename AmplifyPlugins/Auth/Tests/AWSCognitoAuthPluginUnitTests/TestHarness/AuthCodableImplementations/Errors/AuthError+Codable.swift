//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify

extension AuthError: Codable {

    enum CodingKeys: String, CodingKey {
        case errorType
        case errorMessage
        case recoverySuggestion
        case cause
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let errorType = try values.decode(String.self, forKey: .errorType)
        let errorMessage = try values.decode(String.self, forKey: .errorMessage)
        let recoverySuggestion = try values.decode(String.self, forKey: .recoverySuggestion)

        // TODO: Use cause in the error
        let cause = try values.decode([String: String].self, forKey: .cause)

        switch errorType {
        case "NotAuthorizedException":
            self = .notAuthorized(errorMessage, recoverySuggestion, nil)
        default:
            fatalError("error not implemented")
        }
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }

}
