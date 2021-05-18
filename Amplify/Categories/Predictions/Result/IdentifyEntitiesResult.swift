//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct IdentifyEntitiesResult: IdentifyResult {

    /// List of 'Entity' as a result of Identify query
    public let entities: [Entity]

    public init(entities: [Entity]) {
        self.entities = entities
    }
}
