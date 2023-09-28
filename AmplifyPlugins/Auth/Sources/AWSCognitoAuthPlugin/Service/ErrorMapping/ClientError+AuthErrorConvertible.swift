//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import ClientRuntime

extension ClientError: AuthErrorConvertible {
    var fallbackDescription: String { "Client Error" }

    var authError: AuthError {
        switch self {
        case .pathCreationFailed(let message),
                .queryItemCreationFailed(let message),
                .serializationFailed(let message),
                .dataNotFound(let message):
            return .service(message, "", self)

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
