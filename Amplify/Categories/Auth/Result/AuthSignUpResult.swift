//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthSignUpResult {

    /// Indicate whether the signUp flow is completed.
    public var isSignupComplete: Bool {
        return nextStep.signUpStep == .done
    }

    public let nextStep: AuthNextSignUpStep

    public init(_ nextStep: AuthNextSignUpStep) {
        self.nextStep = nextStep
    }
}
