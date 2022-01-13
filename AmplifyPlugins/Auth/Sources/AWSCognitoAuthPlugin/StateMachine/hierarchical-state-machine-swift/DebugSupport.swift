//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] { get }
}

extension State where Self: CustomDebugDictionaryConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
