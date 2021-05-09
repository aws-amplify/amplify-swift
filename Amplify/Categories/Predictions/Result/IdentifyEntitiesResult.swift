//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct IdentifyEntitiesResult: IdentifyResult {

    /// <#Description#>
    public let entities: [Entity]

    /// <#Description#>
    /// - Parameter entities: <#entities description#>
    public init(entities: [Entity]) {
        self.entities = entities
    }
}
