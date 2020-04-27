//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct AuthNextSignUpStep {

    /// Indicates the next step to follow for signUp
    let signUpStep: AuthSignUpStep

    /// Any additional info returned from the authentication provider. Check plugin for more information.
    let additionalInfo: [String: String]?

    /// Details about the
    let codeDeliveryDetails: AuthCodeDeliveryDetails?

    public init(_ signUpStep: AuthSignUpStep,
                additionalInfo: [String: String]? = nil,
                codeDeliveryDetails: AuthCodeDeliveryDetails? = nil) {
        self.signUpStep = signUpStep
        self.additionalInfo = additionalInfo
        self.codeDeliveryDetails = codeDeliveryDetails
    }
}
