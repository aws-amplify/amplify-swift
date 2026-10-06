//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct SRPStateData {
    package let username: String
    package let password: String
    package let NHexValue: String
    package let gHexValue: String
    package let srpKeyPair: SRPKeys
    package let clientTimestamp: Date

    package init(
        username: String,
        password: String,
        NHexValue: String,
        gHexValue: String,
        srpKeyPair: SRPKeys,
        clientTimestamp: Date
    ) {
        self.username = username
        self.password = password
        self.NHexValue = NHexValue
        self.gHexValue = gHexValue
        self.srpKeyPair = srpKeyPair
        self.clientTimestamp = clientTimestamp
    }
}

extension SRPStateData: Equatable {
    package static func == (lhs: SRPStateData, rhs: SRPStateData) -> Bool {
        return true
    }
}

extension SRPStateData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "username": username.maskedForLog(),
            "password": password.redactedForLog(),
            "NHexValue": NHexValue.maskedForLog(),
            "gHexValue": gHexValue.maskedForLog(),
            "srpKeyPair": """
                <privateKey \(srpKeyPair.privateKeyHexValue.maskedForLog())>, \
                <publicKey \(srpKeyPair.publicKeyHexValue.maskedForLog())>
                """,
            "clientTimestamp": clientTimestamp
        ]
    }
}

extension SRPStateData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension SRPStateData: Codable { }
