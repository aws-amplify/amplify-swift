//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum HostedUIError: Error {

    case signInURI

    case signOutURI

    case proofCalculation

    case codeValidation

    case tokenParsing

    case serviceMessage(String)

    case cancelled

    case invalidContext

    case unknown
}

extension HostedUIError: Equatable { }
