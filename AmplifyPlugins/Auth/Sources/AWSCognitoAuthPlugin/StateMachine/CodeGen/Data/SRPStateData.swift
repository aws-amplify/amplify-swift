//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct SRPStateData {
    let username: String
    let password: String
    let NHexValue: String
    let gHexValue: String
    let srpKeyPair: SRPKeys
    let deviceMetadata: DeviceMetadata
    let clientTimestamp: Date

    init(
        username: String,
        password: String,
        NHexValue: String,
        gHexValue: String,
        srpKeyPair: SRPKeys,
        deviceMetadata: DeviceMetadata,
        clientTimestamp: Date
    ) {
        self.username = username
        self.password = password
        self.NHexValue = NHexValue
        self.gHexValue = gHexValue
        self.srpKeyPair = srpKeyPair
        self.deviceMetadata = deviceMetadata
        self.clientTimestamp = clientTimestamp
    }

}

extension SRPStateData: Equatable {
    static func == (lhs: SRPStateData, rhs: SRPStateData) -> Bool {
        return true
    }
}

extension SRPStateData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "password": password.redacted(),
            "NHexValue": NHexValue,
            "gHexValue": gHexValue,
            "srpKeyPair": """
                <privateKey \(srpKeyPair.privateKeyHexValue)>, \
                <publicKey \(srpKeyPair.publicKeyHexValue)>
                """,
            "deviceMetadata": deviceMetadata,
            "clientTimestamp": clientTimestamp
        ]
    }
}

extension SRPStateData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension SRPStateData: Codable { }
