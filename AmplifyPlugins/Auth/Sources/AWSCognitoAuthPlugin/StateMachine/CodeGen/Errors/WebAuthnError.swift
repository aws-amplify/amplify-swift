//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AuthenticationServices

enum WebAuthnError: Error {
    case userCancelled
    case assertionFailed(error: ASAuthorizationError)
    case creationFailed(error: ASAuthorizationError)
    case credentialAlreadyExist
    case service(error: Error)
    case unknown(message: String, error: Error? = nil)
}

extension WebAuthnError: Equatable {
    static func == (lhs: WebAuthnError, rhs: WebAuthnError) -> Bool {
        switch (lhs, rhs) {

        case (.userCancelled, .userCancelled):
            return true
        case (.assertionFailed(let lError), .assertionFailed(let rError)):
            return lError == rError
        case (.creationFailed(let lError), .creationFailed(let rError)):
            return lError == rError
        case (.credentialAlreadyExist, .credentialAlreadyExist):
            return true
        case (.service(let lhsError), .service(let rhsError)):
            return areEquals(lhsError, rhsError)
        case (.unknown(let lhsMessage, let lhsError), .unknown(let rhsMessage, let rhsError)):
            return lhsMessage == rhsMessage && areEquals(lhsError, rhsError)
        default:
            return false
        }
    }

    private static func areEquals(_ lhsError: Error?, _ rhsError: Error?) -> Bool {
        guard let lhsError, let rhsError else {
            return false
        }
        let left = lhsError as NSError
        let right = rhsError as NSError
        return left.code == right.code &&
            left.domain == right.domain
    }
}
