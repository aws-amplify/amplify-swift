//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol SRPClientBehavior {

    var kHexValue: String { get }

    func generateClientKeyPair() -> SRPKeys

    func calculateSharedSecret(username: String,
                               password: String,
                               saltHexValue: String,
                               clientPrivateKeyHexValue: String,
                               clientPublicKeyHexValue: String,
                               serverPublicKeyHexValue: String) throws -> String

    static func calculateUHexValue(clientPublicKeyHexValue: String, serverPublicKeyHexValue: String) throws -> String

    static func generateAuthenticationKey(sharedSecretHexValue: String, uHexValue: String) throws -> Data
}

enum SRPError: Error {

    case calculation

    case numberConversion

    case illegalParameter
}
