//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct AuthNextUpdateAttributeStep {

    let updateAttributeStep: AuthUpdateAttributeStep

    /// Any additional info returned from the authentication provider. Check plugin for more information.
    let additionalInfo: [String: String]?

    /// Details about the delivery of code
    let codeDeliveryDetails: AuthCodeDeliveryDetails?

    public init(_ updateAttributeStep: AuthUpdateAttributeStep,
                additionalInfo: [String: String]? = nil,
                codeDeliveryDetails: AuthCodeDeliveryDetails? = nil) {
        self.updateAttributeStep = updateAttributeStep
        self.additionalInfo = additionalInfo
        self.codeDeliveryDetails = codeDeliveryDetails
    }
}
