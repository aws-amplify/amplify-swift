//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct IdentityPoolConfigurationData: Equatable {
    package let poolId: String
    package let region: String

    package init(
        poolId: String,
        region: String
    ) {
        self.poolId = poolId
        self.region = region
    }
}

extension IdentityPoolConfigurationData: Codable { }

extension IdentityPoolConfigurationData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "poolId": poolId.maskedForLog(interiorCount: 4, retainingCount: 4),
            "region": region.redactedForLog()
        ]
    }
}

extension IdentityPoolConfigurationData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

// Plain values.
extension IdentityPoolConfigurationData: Sendable { }
