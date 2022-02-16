//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SignUpError: Error {
    case invalidState(message: String)
    case invalidUsername(message: String)
    case missingPassword(message: String)
    case invalidPassword(message: String)
    case invalidConfirmationCode(message: String)
    case service(error: Swift.Error)
}

extension SignUpError: Equatable {
    static func == (lhs: SignUpError, rhs: SignUpError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidState, .invalidState):
            return true
        case (.invalidUsername, .invalidUsername):
            return true
        case (.missingPassword, .missingPassword):
            return true
        case (.invalidPassword, .invalidPassword):
            return true
        case (.invalidConfirmationCode, .invalidConfirmationCode):
            return true
        case (.service, .service):
            return true
        default:
            return false
        }
    }
}

