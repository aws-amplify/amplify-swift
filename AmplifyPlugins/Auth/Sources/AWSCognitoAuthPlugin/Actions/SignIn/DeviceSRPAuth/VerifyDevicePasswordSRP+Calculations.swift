//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

extension VerifyDevicePasswordSRP {

    // swiftlint:disable:next function_parameter_count identifier_name
    func signature(deviceGroupKey: String,
                   deviceKey: String,
                   deviceSecret: String,
                   saltHex: String,
                   secretBlock: Data,
                   serverPublicBHexString: String,
                   srpClient: SRPClientBehavior) throws -> String {

        let sharedSecret = try sharedSecret(
            username: "\(deviceGroupKey)\(deviceKey)",
            password: deviceSecret,
            saltHex: saltHex,
            serverPublicBHexString: serverPublicBHexString,
            srpClient: srpClient)

        do {
            let dateStr = stateData.clientTimestamp.utcString
            let clientClass = type(of: srpClient)
            // swiftlint:disable:next identifier_name
            let u = try clientClass.calculateUHexValue(
                clientPublicKeyHexValue: stateData.srpKeyPair.publicKeyHexValue,
                serverPublicKeyHexValue: serverPublicBHexString)
            // HKDF
            let authenticationKey = try clientClass.generateAuthenticationKey(
                sharedSecretHexValue: sharedSecret,
                uHexValue: u)

            // Signature
            let signature = generateSignature(
                srpTimeStamp: dateStr,
                authenticationKey: authenticationKey,
                deviceKey: deviceKey,
                deviceGroupKey: deviceGroupKey,
                serviceSecretBlock: secretBlock)

            return signature.base64EncodedString()
        } catch let error as SRPError {
            let authError = SignInError.calculation(error)
            throw authError
        } catch {
            let message = "Could not calculate signature"
            let authError = SignInError.configuration(message: message)
            throw authError
        }
    }

    func sharedSecret(username: String,
                      password: String,
                      saltHex: String,
                      serverPublicBHexString: String,
                      srpClient: SRPClientBehavior) throws -> String {
        do {
            let srpKeyPair = stateData.srpKeyPair
            return try srpClient.calculateSharedSecret(
                username: username,
                password: password,
                saltHexValue: saltHex,
                clientPrivateKeyHexValue: srpKeyPair.privateKeyHexValue,
                clientPublicKeyHexValue: srpKeyPair.publicKeyHexValue,
                serverPublicKeyHexValue: serverPublicBHexString)
        } catch let error as SRPError {
            let authError = SignInError.calculation(error)
            throw authError
        } catch {
            let message = "Could not calculate shared secret"
            let authError = SignInError.configuration(message: message)
            throw authError
        }
    }

    func generateSignature(srpTimeStamp: String,
                           authenticationKey: Data,
                           deviceKey: String,
                           deviceGroupKey: String,
                           serviceSecretBlock: Data) -> Data {
        let key = SymmetricKey(data: authenticationKey)
        var hmac = HMAC<SHA256>.init(key: key)
        hmac.update(data: Data(deviceGroupKey.utf8))
        hmac.update(data: Data(deviceKey.utf8))
        hmac.update(data: serviceSecretBlock)
        hmac.update(data: Data(srpTimeStamp.utf8))
        return Data(hmac.finalize())
    }
}
