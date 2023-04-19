//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CommonCrypto
import CryptoKit

// https://tools.ietf.org/html/rfc5869
public enum HMACKeyDerivationFunction {

    public static func generateDerivedKey(keyingMaterial: Data,
                                          salt: Data,
                                          info: String?,
                                          outputLength: Int) -> Data {
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, *) {
            return generateHKDF(keyingMaterial: keyingMaterial,
                                salt: salt,
                                info: info,
                                outputLength: outputLength)
        } else {
            let pseudoRandomKey = extractPseudoRandomKey(salt: salt, inputKeyMaterial: keyingMaterial)
            return expand(pseudoRandomKey: pseudoRandomKey, info: info?.data(using: .utf8), outputLength: outputLength)
        }
    }

    @available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
    private static func generateHKDF(keyingMaterial: Data,
                             salt: Data,
                             info: String?,
                             outputLength: Int) -> Data {
        let key = SymmetricKey(data: keyingMaterial)
        var hkdf: SymmetricKey
        if let infoData = info?.data(using: .utf8) {
            hkdf = HKDF<SHA256>.deriveKey(inputKeyMaterial: key,
                                          salt: salt, info: infoData,
                                          outputByteCount: outputLength)

        } else {
            hkdf = HKDF<SHA256>.deriveKey(inputKeyMaterial: key,
                                          salt: salt,
                                          outputByteCount: outputLength)
        }
        return hkdf.withUnsafeBytes { buffPointer in
            return Data(Array(buffPointer))
        }
    }

    private static func extractPseudoRandomKey(salt: Data, inputKeyMaterial: Data) -> Data {
        let key = SymmetricKey(data: salt)
        let hmac = HMAC<SHA256>.authenticationCode(for: inputKeyMaterial, using: key)
        return Data(hmac)
    }

    private static func expand(pseudoRandomKey: Data, info: Data?, outputLength: Int) -> Data {

        let n = UInt(ceil(Double(outputLength) / Double(CC_SHA256_DIGEST_LENGTH)))
        var outputKeyMaterial = Data()
        var previousT = Data()
        for index in 1 ... n {
            let t = calculateT(pseudoRandomKey: pseudoRandomKey,
                               previousT: previousT,
                               info: info,
                               i: UInt8(index))
            outputKeyMaterial.append(t)
            previousT = t
        }
        return outputKeyMaterial.subdata(in: 0 ..< Int(outputLength))
    }

    private static func calculateT(pseudoRandomKey: Data, previousT: Data, info: Data?, i: UInt8 ) -> Data {

        let key = SymmetricKey(data: pseudoRandomKey)
        var hmac = HMAC<SHA256>.init(key: key)
        hmac.update(data: previousT)
        if let infoData = info {
            hmac.update(data: infoData)
        }
        hmac.update(data: Data(bytes: [i], count: 1))
        let hmacFinal = hmac.finalize()
        return Data(hmacFinal)
    }
}
