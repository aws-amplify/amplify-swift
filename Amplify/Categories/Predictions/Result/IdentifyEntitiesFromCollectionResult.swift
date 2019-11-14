//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyEntitiesFromCollectionResult: IdentifyResult {
    public let entities: [CollectionEntity]

    public init(entities: [CollectionEntity]) {
        self.entities = entities
    }
}
