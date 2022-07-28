//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit
import AmplifyBigInteger

public typealias BigInt = AmplifyBigInt

public struct SRPClientState {

    public let privateA: BigInt
    public let publicA: BigInt

    public init(commonState: SRPCommonState) {
        self.privateA = SRPClientState.calculatePrivateA(prime: commonState.prime)
        self.publicA = SRPClientState.calculatePublicA(privateA: privateA,
                                                       generator: commonState.generator,
                                                       prime: commonState.prime)
    }

    private static func calculatePrivateA(prime N: BigInt) -> BigInt {
        let byteSize = 256 / 8
        var randomInt: BigInt
        repeat {
            randomInt = generateRandomUnsigned(of: byteSize)
        } while (randomInt >= N)
        return randomInt
    }

    private static func calculatePublicA(privateA: BigInt,
                                 generator: BigInt,
                                 prime: BigInt) -> BigInt {
        return generator.pow(privateA, modulus: prime)
    }

    private static func generateRandomUnsigned(of byteSize: Int) -> BigInt {
        var randomBytes = [UInt8](repeating: 0, count: byteSize)
        let result = SecRandomCopyBytes(kSecRandomDefault, byteSize, &randomBytes)
        guard result == errSecSuccess else {
            fatalError("Error occured in generating random bytes")
        }
        return BigInt(unsignedData: randomBytes)
    }

    public static func calculcateU(publicClientKey: [UInt8], publicServerKey: [UInt8]) -> BigInt {
        var digest = SHA256()
        digest.update(data: publicClientKey)
        digest.update(data: publicServerKey)
        let hashBytes = [UInt8](digest.finalize())
        return BigInt(unsignedData: hashBytes)
    }

    public static func calculateSessionKey(username: String,
                                           password: String,
                                           publicClientKey: BigInt,
                                           privateClientKey: BigInt,
                                           publicServerKey: BigInt,
                                           salt: BigInt,
                                           commonState: SRPCommonState) -> BigInt {

        // Calculations are detailed in RFC - https://datatracker.ietf.org/doc/html/rfc2945
        // Calculate x = SHA(<salt> | SHA(<username> | ":" | <raw password>))
        let usernamePassword = [UInt8]("\(username):\(password)".utf8)
        let usernamePasswordHash = SHA256.hash(data: usernamePassword)
        let xHash = SHA256.hash(data: AmplifyBigIntHelper.getSignedData(num: salt) + usernamePasswordHash)
        let x = BigInt(unsignedData: [UInt8](xHash))

        // We have to convert few values to the signed version to make it work with Cognito.
        let signedPubClient = AmplifyBigIntHelper.getSignedData(num: publicClientKey)
        let signedPubServer = AmplifyBigIntHelper.getSignedData(num: publicServerKey)

        let u = calculcateU(publicClientKey: signedPubClient, publicServerKey: signedPubServer)

        // calculate S = (B - k*g^x)^(privateClientKey+u*x)
        let base = publicServerKey - (commonState.k * commonState.generator.pow(x, modulus: commonState.prime))
        let exp = privateClientKey + (u * x)
        let S = base.pow(exp, modulus: commonState.prime)
        return S
    }

    public static func calculateDevicePasswordVerifier(
        deviceGroupKey: String,
        deviceKey: String,
        password: String,
        commonState: SRPCommonState) -> (salt: BigInt, passwordVerifier: BigInt) {

            // Salt (16 random bytes)
            let salt = generateRandomUnsigned(of: 16)

            //FULL_PASSWORD = SHA256_HASH(DeviceGroupKey + username + ":" + RANDOM_PASSWORD)
            let fullPassword = [UInt8]("\(deviceGroupKey)\(deviceKey):\(password)".utf8)
            let fullPasswordHash = SHA256.hash(data: fullPassword)
            let hashedSaltAndFullPassword = SHA256.hash(
                data: AmplifyBigIntHelper.getSignedData(num: salt) + fullPasswordHash)

            // X = Salt + FULL_PASSWORD
            let x = BigInt(unsignedData: [UInt8](hashedSaltAndFullPassword))

            //PasswordVerifier = g(salt + FULL_PASSWORD) (mod N)
            let passwordVerifier = commonState.generator.pow(x, modulus: commonState.prime)

            return (salt, passwordVerifier)
        }

}
