//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthSignUpResult {

    /// Indicate whether the signUp flow is completed.
    public var isSignupComplete: Bool {
        switch nextStep {
        case .done:
            return true
        default:
            return false
        }
    }

    /// <#Description#>
    public let nextStep: AuthSignUpStep

    /// <#Description#>
    /// - Parameter nextStep: <#nextStep description#>
    public init(_ nextStep: AuthSignUpStep) {
        self.nextStep = nextStep
    }
}
