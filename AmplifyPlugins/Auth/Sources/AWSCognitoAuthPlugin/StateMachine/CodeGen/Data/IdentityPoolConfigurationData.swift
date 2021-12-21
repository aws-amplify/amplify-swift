//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct IdentityPoolConfigurationData: Equatable {
    public let poolId: String
    public let region: String

    public init(poolId: String,
                region: String)
    {
        self.poolId = poolId
        self.region = region
    }

}

extension IdentityPoolConfigurationData: Codable { }

extension IdentityPoolConfigurationData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "poolId": poolId.masked(interiorCount: 4, retainingCount: 4),
            "region": region.masked(interiorCount: 4, retainingCount: 4)
        ]
    }
}

extension IdentityPoolConfigurationData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}

