//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct IdentityPoolConfigurationData: Equatable {
    let poolId: String
    let region: String

    init(poolId: String,
                region: String) {
        self.poolId = poolId
        self.region = region
    }

}

extension IdentityPoolConfigurationData: Codable { }

extension IdentityPoolConfigurationData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "poolId": poolId.masked(interiorCount: 4, retainingCount: 4),
            "region": region.redacted()
        ]
    }
}

extension IdentityPoolConfigurationData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
