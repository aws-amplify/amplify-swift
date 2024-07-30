//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum HostedUIError: Error {

    case signInURI

    case tokenURI

    case signOutURI

    case signOutRedirectURI

    case proofCalculation

    case codeValidation

    case tokenParsing

    case serviceMessage(String)

    case pluginConfiguration(String)

    case cancelled

    case invalidContext

    case unableToStartASWebAuthenticationSession

    case unknown
}

extension HostedUIError: Equatable { }
