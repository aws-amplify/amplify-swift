//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthSignUpResult {

    public let userConfirmed: Bool

    public let codeDeliveryDetails: AuthCodeDeliveryDetails?

    public init(userConfirmed: Bool, codeDeliveryDetails: AuthCodeDeliveryDetails?) {
        self.userConfirmed = userConfirmed
        self.codeDeliveryDetails = codeDeliveryDetails
    }
}
