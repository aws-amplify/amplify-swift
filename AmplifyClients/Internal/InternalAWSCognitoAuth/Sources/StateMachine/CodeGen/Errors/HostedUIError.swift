//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package enum HostedUIError: Error {

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

    /// The token response was refused by the flow's `HostedUIIdentityPolicy`. Only produced when a policy
    /// is set, which the plugin never does.
    case unexpectedIdentity(HostedUIIdentityMismatch)

    case unknown
}

extension HostedUIError: Equatable { }
