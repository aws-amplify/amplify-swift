//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin

extension AuthError {

    func info() -> String {
        switch self {

        case .configuration:
            return "configuration"
        case .service(_, _, let internalError):
            return "service: \(internalError?.info() ?? "" )"
        case .unknown(_, let internalError):
            return "unknown: \(internalError?.info() ?? "" )"
        case .validation(let field, _, _, _):
            return "validation \(field)"
        case .notAuthorized:
            return "notAuthorized"
        case .invalidState:
            return "invalidState"
        case .signedOut:
            return "signedOut"
        case .sessionExpired:
            return "sessionExpired"
        }
    }
}

extension AWSCognitoAuthError {

    func info() -> String {
        return "\(self)"
    }

    func testunk() {
        switch self {
        case .aliasExists:
            print("\(self)")
        default:
            print("\(self)")
        }
    }
}

extension Error {

    func info() -> String {
        if let authError = self as? AuthError {
            return authError.info()
        }
        if let authError = self as? AWSCognitoAuthError {
            return authError.info()
        }
        return "\(self)"
    }
}
