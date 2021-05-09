//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthUpdateAttributeResult {

    /// <#Description#>
    public let isUpdated: Bool

    /// <#Description#>
    public let nextStep: AuthUpdateAttributeStep

    /// <#Description#>
    /// - Parameters:
    ///   - isUpdated: <#isUpdated description#>
    ///   - nextStep: <#nextStep description#>
    public init(isUpdated: Bool, nextStep: AuthUpdateAttributeStep) {
        self.isUpdated = isUpdated
        self.nextStep = nextStep
    }
}
