//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthUpdateAttributeResult {

    public let isUpdated: Bool

    public let nextStep: AuthUpdateAttributeStep

    public init(isUpdated: Bool, nextStep: AuthUpdateAttributeStep) {
        self.isUpdated = isUpdated
        self.nextStep = nextStep
    }
}
