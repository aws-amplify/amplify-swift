//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct SignedOutData {
    let lastKnownUserName: String?

    init(
        lastKnownUserName: String? = nil
    ) {
        self.lastKnownUserName = lastKnownUserName
    }
}

extension SignedOutData: Codable { }

extension SignedOutData: Equatable { }

extension SignedOutData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "lastKnownUserName": lastKnownUserName.masked(),
        ]
    }
}

extension SignedOutData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
