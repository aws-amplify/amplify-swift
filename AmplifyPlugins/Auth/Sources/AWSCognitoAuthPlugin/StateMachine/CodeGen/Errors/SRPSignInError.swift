//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum SRPSignInError: Error {
    case configuration(message: String)
    case service(error: Swift.Error)
    case inputValidation(field: String)
}

extension SRPSignInError: Equatable {
    public static func == (lhs: SRPSignInError, rhs: SRPSignInError) -> Bool {
        switch (lhs, rhs) {
        case (.configuration, .configuration):
            return true
        case (.service, .service):
            return true
        case (.inputValidation(let lhsField), .inputValidation(let rhsField)):
            return lhsField == rhsField
        default:
            return false
        }
    }
}
