//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct FederatedToken {

    let token: String
    let provider: AuthProvider
    
}

extension FederatedToken: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "provider": provider,
            "token": token.masked()
        ]
    }
}

extension FederatedToken: Codable { }

extension FederatedToken: Equatable { }
