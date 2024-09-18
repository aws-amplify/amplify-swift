//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Smithy
import SmithyHTTPAPI

extension SmithyHTTPAPI.HTTPClientError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .pathCreationFailed(let message),
             .queryItemCreationFailed(let message):
            return .service(message, "", self)
        }
    }
}

extension Smithy.ClientError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .serializationFailed(let message),
             .dataNotFound(let message),
             .invalidValue(let message):
            return .service(message, "Check the underlying error and try again", self)

        case .authError(let message):
            return .notAuthorized(
                message,
                "Check if you are authorized to perform the request"
            )

        case .unknownError(let message):
            return AuthError.unknown(message, self)
        }
    }
}
