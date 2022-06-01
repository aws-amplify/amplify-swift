//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct SignOutEventData: Codable {
    let globalSignOut: Bool

    init(globalSignOut: Bool) {
        self.globalSignOut = globalSignOut
    }
}

extension SignOutEventData: Equatable { }

extension SignOutEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "globalSignOut": globalSignOut
        ]
    }
}
extension SignOutEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
