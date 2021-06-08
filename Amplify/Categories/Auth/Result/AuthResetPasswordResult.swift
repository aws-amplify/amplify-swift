//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Result for Auth.resetPassword api
public struct AuthResetPasswordResult {

    /// Flag to represent whether the reset password flow is complete.
    ///
    /// `true` if the reset password flow is complete.
    public let isPasswordReset: Bool

    /// Next steps to follow for reset password api.
    public let nextStep: AuthResetPasswordStep

    public init(isPasswordReset: Bool, nextStep: AuthResetPasswordStep) {
        self.isPasswordReset = isPasswordReset
        self.nextStep = nextStep
    }
}

/// The next step in Auth.resetPassword api
public enum AuthResetPasswordStep {

    /// Next step is to confirm the password with a code.
    ///
    /// Invoke Auth.confirmResetPassword with new password and the confirmation code for th user
    /// for which reset password was invoked. `AuthCodeDeliveryDetails` provides the details to which
    /// the confirmation code was send and `AdditionalInfo` will provide more details if present.
    case confirmResetPasswordWithCode(AuthCodeDeliveryDetails, AdditionalInfo?)

    /// Reset password complete, there are no next step.
    case done

}
