//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthAssociateSoftwareTokenResult {

    /// Informs whether the user has token associated or not.
    ///
    /// When this value is false, it means that there are more steps to follow for the associate token flow. Check `nextStep`
    /// to understand the next flow. If `isTokenAssociated` is true, associate token flow has been completed.
    public var isTokenAssociated: Bool {
        switch nextStep {
        case .done:
            return true
        default:
            return false
        }
    }

    /// Shows the next step required to complete the associate token flow.
    ///
    public var nextStep: AuthAssociateSoftwareTokenStep

    public init(nextStep: AuthAssociateSoftwareTokenStep) {
        self.nextStep = nextStep
    }
}
