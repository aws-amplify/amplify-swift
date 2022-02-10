//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SignedOutData {
    public let lastKnownUserName: String?

    public init(
        lastKnownUserName: String? = nil
    ) {
        self.lastKnownUserName = lastKnownUserName
    }
}

extension SignedOutData: Codable { }

extension SignedOutData: Equatable { }

extension SignedOutData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "lastKnownUserName": lastKnownUserName.masked(),
        ]
    }
}

extension SignedOutData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
