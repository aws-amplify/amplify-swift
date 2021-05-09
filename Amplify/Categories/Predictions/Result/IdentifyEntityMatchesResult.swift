//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct IdentifyEntityMatchesResult: IdentifyResult {

    /// <#Description#>
    public let entities: [EntityMatch]

    /// <#Description#>
    /// - Parameter entities: <#entities description#>
    public init(entities: [EntityMatch]) {
        self.entities = entities
    }
}
