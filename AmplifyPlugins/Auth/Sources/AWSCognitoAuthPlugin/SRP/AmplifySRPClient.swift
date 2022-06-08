//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AmplifySRP
import AmplifyBigInteger

struct AmplifySRPClient: SRPClientBehavior {

    let commonState: SRPCommonState
    let client: SRPClientState

    init(NHexValue: String, gHexValue: String) throws {
        guard let N = BigInt(NHexValue, radix: 16),
              let g = BigInt(gHexValue, radix: 16)
        else {
                  throw SRPError.numberConversion
              }
        self.commonState = SRPCommonState(prime: N, generator: g)
        self.client = SRPClientState(commonState: commonState)
    }

    var kHexValue: String {
        commonState.k.asString(radix: 16)
    }

    func generateClientKeyPair() -> SRPKeys {
        let publicHexValue = client.publicA.asString(radix: 16)
        let privateHexValue = client.privateA.asString(radix: 16)
        let srpKeys = SRPKeys(publicKeyHexValue: publicHexValue,
                              privateKeyHexValue: privateHexValue)
        return srpKeys
    }

    func calculateSharedSecret(username: String,
                               password: String,
                               saltHexValue: String,
                               clientPrivateKeyHexValue: String,
                               clientPublicKeyHexValue: String,
                               serverPublicKeyHexValue: String) throws -> String {
        guard let clientPublicNum = BigInt(clientPublicKeyHexValue, radix: 16) else {
            throw SRPError.numberConversion
        }
        guard let clientPrivateNum = BigInt(clientPrivateKeyHexValue, radix: 16) else {
            throw SRPError.numberConversion
        }
        guard let saltNum = BigInt(saltHexValue, radix: 16) else {
            throw SRPError.numberConversion
        }
        guard let serverPublicKeyNum = BigInt(serverPublicKeyHexValue, radix: 16) else {
            throw SRPError.numberConversion
        }
        guard serverPublicKeyNum % commonState.prime != BigInt(0) else {
            throw SRPError.illegalParameter
        }
        let sharedSecret = SRPClientState.calculateSessionKey(username: username,
                                                              password: password,
                                                              publicClientKey: clientPublicNum,
                                                              privateClientKey: clientPrivateNum,
                                                              publicServerKey: serverPublicKeyNum,
                                                              salt: saltNum,
                                                              commonState: commonState)
        return sharedSecret.asString(radix: 16)
    }

    static func calculateUHexValue(clientPublicKeyHexValue: String,
                                   serverPublicKeyHexValue: String) throws -> String {
        guard let clientPublicNum = BigInt(clientPublicKeyHexValue, radix: 16) else {
            throw SRPError.numberConversion
        }
        guard let serverPublicNum = BigInt(serverPublicKeyHexValue, radix: 16) else {
            throw SRPError.numberConversion
        }
        let signedClientPublicKey = AmplifyBigIntHelper.getSignedData(num: clientPublicNum)
        let signedServerPublicKey = AmplifyBigIntHelper.getSignedData(num: serverPublicNum)

        let u = SRPClientState.calculcateU(publicClientKey: signedClientPublicKey,
                                           publicServerKey: signedServerPublicKey)

        return u.asString(radix: 16)
    }

    static func generateAuthenticationKey(sharedSecretHexValue: String, uHexValue: String) throws -> Data {
        guard let sharedSecretNum = BigInt(sharedSecretHexValue, radix: 16) else {
            throw SRPError.numberConversion
        }
        guard let uNum = BigInt(uHexValue, radix: 16) else {
            throw SRPError.numberConversion
        }
        let keyingMaterial = AmplifyBigIntHelper.getSignedData(num: sharedSecretNum)
        let salt = AmplifyBigIntHelper.getSignedData(num: uNum)

        let authenticationkey = HMACKeyDerivationFunction.generateDerivedKey(
            keyingMaterial: Data(keyingMaterial),
            salt: Data(salt),
            info: "Caldera Derived Key",
            outputLength: 16)
        return authenticationkey
    }

}
