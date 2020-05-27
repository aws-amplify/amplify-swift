//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthResetPasswordResult {

    public let isPasswordReset: Bool

    public let nextStep: AuthResetPasswordStep

    public init(isPasswordReset: Bool, nextStep: AuthResetPasswordStep) {
        self.isPasswordReset = isPasswordReset
        self.nextStep = nextStep
    }
}

public enum AuthResetPasswordStep {

    case confirmResetPasswordWithCode(AuthCodeDeliveryDetails, AdditionalInfo?)

    case done

}
