//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthResetPasswordResult {

    /// <#Description#>
    public let isPasswordReset: Bool

    /// <#Description#>
    public let nextStep: AuthResetPasswordStep

    /// <#Description#>
    /// - Parameters:
    ///   - isPasswordReset: <#isPasswordReset description#>
    ///   - nextStep: <#nextStep description#>
    public init(isPasswordReset: Bool, nextStep: AuthResetPasswordStep) {
        self.isPasswordReset = isPasswordReset
        self.nextStep = nextStep
    }
}

/// <#Description#>
public enum AuthResetPasswordStep {

    /// <#Description#>
    case confirmResetPasswordWithCode(AuthCodeDeliveryDetails, AdditionalInfo?)

    /// <#Description#>
    case done

}
