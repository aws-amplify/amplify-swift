//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct FederatedToken {

    package let token: String
    package let provider: EngineAuthProvider

    package init(
        token: String,
        provider: EngineAuthProvider
    ) {
        self.token = token
        self.provider = provider
    }
}

extension FederatedToken: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "provider": provider,
            "token": token.maskedForLog()
        ]
    }
}

extension FederatedToken: Codable { }

extension FederatedToken: Equatable { }
