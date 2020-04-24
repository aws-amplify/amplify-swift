//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct AuthNextSignInStep {

    public let signInStep: AuthSignInStep
    public let additionalInfo: [String: String]?
    public let codeDeliveryDetails: AuthCodeDeliveryDetails?

    public init(_ signInStep: AuthSignInStep,
                additionalInfo: [String: String]? = nil,
                codeDeliveryDetails: AuthCodeDeliveryDetails? = nil) {
        self.signInStep = signInStep
        self.additionalInfo = additionalInfo
        self.codeDeliveryDetails = codeDeliveryDetails
    }
}
