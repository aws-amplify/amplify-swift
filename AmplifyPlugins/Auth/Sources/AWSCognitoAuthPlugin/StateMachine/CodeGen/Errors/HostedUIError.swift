//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum HostedUIError: Error {

    case signInURI

    case proofCalculation

    case codeValidation

    case serviceMessage(String)
}

extension HostedUIError: Equatable {
}
