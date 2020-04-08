//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthForgotPasswordResult {

    public let codeDeliveryDetails: AuthCodeDeliveryDetails

    public init(codeDeliveryDetails: AuthCodeDeliveryDetails) {
        self.codeDeliveryDetails = codeDeliveryDetails
    }
}
