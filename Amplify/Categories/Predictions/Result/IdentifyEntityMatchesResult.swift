//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyEntityMatchesResult: IdentifyResult {
    public let entities: [EntityMatch]

    public init(entities: [EntityMatch]) {
        self.entities = entities
    }
}
