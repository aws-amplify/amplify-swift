//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSSDKHTTPAuth
import Smithy
import SmithyEventStreamsAPI
import SmithyEventStreamsAuthAPI
import SmithyHTTPAuthAPI
import struct Foundation.Data
import AwsCommonRuntimeKit
import SmithyHTTPAuth

extension AWSSigV4Signer: MessageDataSigner {

    public func signEvent(
        payload: Data,
        previousSignature: String,
        signingProperties: Attributes
    ) async throws -> SigningResult<Message> {
        let signingConfig = signingProperties.get(key: AWSMessageSigner.signingConfigKey)
        guard let signingConfig else {
            throw ClientError.dataNotFound("Failed to sign event stream message due to missing signing config.")
        }
        return try await signEvent(payload: payload, previousSignature: previousSignature, signingConfig: signingConfig)
    }

    /// Signs the event payload and returns the signed event with :date and :chunk-signature headers
    /// - Parameters:
    ///   - payload: The event payload to sign
    ///   - previousSignature: The signature of the previous event, this is used to calculate the signature of
    ///                        the current event payload like a rolling signature calculation.
    ///   - signingConfig: The signing configuration
    /// - Returns: The signed event with :date and :chunk-signature headers
    public func signEvent(payload: Data,
                          previousSignature: String,
                          signingConfig: AWSSigningConfig) async throws -> SigningResult<Message> {
        let signature = try await Signer.signEvent(event: payload,
                                                   previousSignature: previousSignature,
                                                   config: try signingConfig.toCRTType())
        let binarySignature = signature.hexaData

        let message = Message(headers: [ .init(name: ":date",
                                               value: .timestamp(signingConfig.date)),
                                               .init(name: ":chunk-signature",
                                               value: .byteArray(binarySignature))],
                                               payload: payload)

        return SigningResult(output: message, signature: signature)
    }

}
