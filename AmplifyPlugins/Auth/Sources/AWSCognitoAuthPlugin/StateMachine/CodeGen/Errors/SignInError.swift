//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SignInError: Error {
    case configuration(message: String)
    case service(error: Swift.Error)
    case inputValidation(field: String)
    case invalidServiceResponse(message: String)
    case calculation(SRPError)
    case hostedUI(HostedUIError)
    case unknown(message: String)
}

extension SignInError: Equatable {
    static func == (lhs: SignInError, rhs: SignInError) -> Bool {
        switch (lhs, rhs) {
        case (.configuration, .configuration):
            return true
        case (.service, .service):
            return true
        case (.inputValidation(let lhsField), .inputValidation(let rhsField)):
            return lhsField == rhsField
        case (.invalidServiceResponse, .invalidServiceResponse):
            return true
        case (.hostedUI(let lhsError), .hostedUI(let rhsError)):
            return lhsError == rhsError
        case (.calculation(let lhsField), .calculation(let rhsField)):
            return lhsField == rhsField
        case (.unknown(let lhs), .unknown(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
