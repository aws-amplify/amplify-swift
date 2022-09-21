//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

extension VerifyPasswordSRP {

    func signature(userIdForSRP: String,
                   saltHex: String,
                   secretBlock: Data,
                   serverPublicBHexString: String,
                   srpClient: SRPClientBehavior,
                   poolId: String) throws -> String {

        let sharedSecret = try sharedSecret(
            userIdForSRP: userIdForSRP,
            saltHex: saltHex,
            serverPublicBHexString: serverPublicBHexString,
            srpClient: srpClient,
            poolId: poolId)

        do {
            let strippedPoolId =  strippedPoolId(poolId)
            let dateStr = stateData.clientTimestamp.utcString
            let clientClass = type(of: srpClient)
            let u = try clientClass.calculateUHexValue( // swiftlint:disable:this identifier_name
                clientPublicKeyHexValue: stateData.srpKeyPair.publicKeyHexValue,
                serverPublicKeyHexValue: serverPublicBHexString)
            // HKDF
            let authenticationkey = try clientClass.generateAuthenticationKey(
                sharedSecretHexValue: sharedSecret,
                uHexValue: u)

            // Signature
            let signature = generateSignature(
                srpTimeStamp: dateStr,
                authenticationKey: authenticationkey,
                srpUserName: userIdForSRP,
                poolName: strippedPoolId,
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

    func sharedSecret(userIdForSRP: String,
                      saltHex: String,
                      serverPublicBHexString: String,
                      srpClient: SRPClientBehavior,
                      poolId: String) throws -> String {
        let strippedPoolId =  strippedPoolId(poolId)
        let usernameForS = "\(strippedPoolId)\(userIdForSRP)"
        do {
            let srpKeyPair = stateData.srpKeyPair
            return try srpClient.calculateSharedSecret(
                username: usernameForS,
                password: stateData.password,
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

    func strippedPoolId(_ poolId: String) -> String {
        let index = poolId.firstIndex(of: "_")!
        return String(poolId[poolId.index(index, offsetBy: 1)...])
    }

    func generateSignature(srpTimeStamp: String,
                           authenticationKey: Data,
                           srpUserName: String,
                           poolName: String,
                           serviceSecretBlock: Data) -> Data {
        let key = SymmetricKey(data: authenticationKey)
        var hmac = HMAC<SHA256>.init(key: key)
        hmac.update(data: poolName.data(using: .utf8)!)
        hmac.update(data: srpUserName.data(using: .utf8)!)
        hmac.update(data: serviceSecretBlock)
        hmac.update(data: srpTimeStamp.data(using: .utf8)!)
        return Data(hmac.finalize())
    }
}
