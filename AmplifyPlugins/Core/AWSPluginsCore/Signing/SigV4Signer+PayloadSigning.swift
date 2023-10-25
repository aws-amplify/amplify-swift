//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

extension SigV4Signer {

    /// Sign a payload with AWS4-HMAC-SHA256-PAYLOAD and
    /// the previous signature in the String to Sign.
    ///
    /// - Parameters:
    ///   - payload: payload to be signed.
    ///   - dateHeader: The date to be included in the string to sign
    /// - Returns: A signed request
    func signWithPreviousSignature(
        payload: Data,
        dateHeader: (key: String, value: Date)
    ) -> Data {
        let timestamp = _timeFormatter.string(from: dateHeader.value)
        let datestamp = _dateFormatter.string(from: dateHeader.value)
        let credentialScope = _credentialScope(
            datestamp: datestamp,
            region: region,
            serviceName: serviceName
        )

        let stringToSign = _stringToSignWithPreviousSignature(
            timestamp: timestamp,
            credentialScope: credentialScope,
            payload: payload,
            dateHeader: dateHeader
        )

        let signingKey = _signingKey(
            region: region,
            secretKey: credential.secretKey,
            datestamp: datestamp
        )

        let signature = _hash(data: stringToSign, key: signingKey)
        _storage.previousSignature = signature.hexDigest()
        return Data(signature)
    }

    // Generate a StringToSign for a AWS4-HMAC-SHA256-PAYLOAD
    // type request, which includes the previous signature.
    func _stringToSignWithPreviousSignature(
        timestamp: String,
        credentialScope: String,
        payload: Data,
        dateHeader: (key: String, value: Date)
    ) -> Data {
        let hashedPayload = SHA256.hash(data: payload).hexDigest()
        let encodedDateHeader = _encodeDateHeader(dateHeader)
        let hashedDateHeader = SHA256.hash(data: encodedDateHeader).hexDigest()
        let stringToSign = [
            "AWS4-HMAC-SHA256-PAYLOAD",
            timestamp,
            credentialScope,
            _storage.previousSignature ?? "",
            hashedDateHeader,
            hashedPayload
        ]
            .joined(separator: "\n")

        return Data(stringToSign.utf8)
    }

    // Encode the date header in timestamp milliseconds big endian format.
    func _encodeDateHeader(_ dateHeader: (key: String, value: Date)) -> Data {
        let headerNameLength = UInt8(Data(dateHeader.key.utf8).count)
        let headerValueType = UInt8(8)
        var headerValue = UInt64(dateHeader.value.timeIntervalSince1970 * 1_000).bigEndian
        let headerValueBytes: [UInt8] = withUnsafeBytes(of: &headerValue, Array.init)
        let headerKey = Data(dateHeader.key.utf8)

        var data = Data()
        data.append(headerNameLength)
        data.append(contentsOf: headerKey)
        data.append(headerValueType)
        data.append(contentsOf: headerValueBytes)
        return data
    }
}
