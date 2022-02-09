//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SignOutEventData: Codable {
    public let globalSignOut: Bool

    public init(globalSignOut: Bool) {
        self.globalSignOut = globalSignOut
    }
}

extension SignOutEventData: Equatable { }

extension SignOutEventData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "globalSignOut": globalSignOut
        ]
    }
}
extension SignOutEventData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}

