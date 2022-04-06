//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public struct SRPStateData {
    let username: String
    let password: String
    let NHexValue: String
    let gHexValue: String
    let srpKeyPair: SRPKeys
    let clientTimestamp: Date

    init(
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
    public static func == (lhs: SRPStateData, rhs: SRPStateData) -> Bool {
        return true
    }
}

extension SRPStateData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "password": password.redacted(),
            "NHexValue": NHexValue,
            "gHexValue": gHexValue,
            "srpKeyPair": """
                <privateKey \(srpKeyPair.privateKeyHexValue)>, \
                <publicKey \(srpKeyPair.publicKeyHexValue)>
                """,
            "clientTimestamp": clientTimestamp
        ]
    }
}

extension SRPStateData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
