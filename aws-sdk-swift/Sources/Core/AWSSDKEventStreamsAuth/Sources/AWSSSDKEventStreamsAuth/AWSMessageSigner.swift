//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyHTTPAuth.AWSSigningConfig
import protocol SmithyEventStreamsAPI.MessageEncoder
import struct SmithyEventStreamsAPI.Message
import protocol SmithyEventStreamsAuthAPI.MessageSigner
import protocol SmithyEventStreamsAuthAPI.MessageDataSigner
import protocol SmithyHTTPAuthAPI.Signer
import struct Smithy.Attributes
import struct Smithy.AttributeKey

/// Signs a `Message` using the AWS SigV4 signing algorithm
public class AWSMessageSigner: MessageSigner {
    let encoder: MessageEncoder
    let signer: () async throws -> MessageDataSigner
    let signingConfig: () async throws -> AWSSigningConfig
    let requestSignature: () -> String
    // Attribute key used to save AWSSigningConfig into signingProperties argument
    //  for AWSSigV4Signer::signEvent call that conforms to Signer::signEvent.
    static let signingConfigKey = AttributeKey<AWSSigningConfig>(name: "EventStreamSigningConfig")

    private var _previousSignature: String?

    /// Returns the previous signature used to sign a message
    /// If no previous signature is available, then the request signature returned
    /// which acts as previous signature for the first message
    var previousSignature: String {
        get {
            if let signature = _previousSignature {
                return signature
            }

            let requestSignature = requestSignature()
            _previousSignature = requestSignature
            return requestSignature
        }
        set {
            _previousSignature = newValue
        }
    }

    public init(encoder: MessageEncoder,
                signer: @escaping () async throws -> MessageDataSigner,
                signingConfig: @escaping () async throws -> AWSSigningConfig,
                requestSignature: @escaping () -> String) {
        self.encoder = encoder
        self.signer = signer
        self.signingConfig = signingConfig
        self.requestSignature = requestSignature
    }

    /// Signs a `Message` using the AWS SigV4 signing algorithm
    /// - Parameter message: `Message` to sign
    /// - Returns: Signed `Message` with `:chunk-signature` & `:date` headers
    public func sign(message: Message) async throws -> Message {
        // encode to bytes
        let encodedMessage = try encoder.encode(message: message)
        let signingConfig = try await self.signingConfig()
        // Fetch signer
        let signer = try await self.signer()
        // Wrap config into signingProperties: Attributes
        var configWrapper = Attributes()
        configWrapper.set(key: AWSMessageSigner.signingConfigKey, value: signingConfig)
        // Sign encoded bytes
        let signingResult = try await signer.signEvent(payload: encodedMessage,
                                                       previousSignature: previousSignature,
                                                       signingProperties: configWrapper)
        previousSignature = signingResult.signature
        return signingResult.output
    }

    /// Signs an empty `Message` using the AWS SigV4 signing algorithm
    /// - Returns: Signed `Message` with `:chunk-signature` & `:date` headers
    public func signEmpty() async throws -> Message {
        let signingConfig = try await self.signingConfig()
        // Fetch signer
        let signer = try await self.signer()
        // Wrap config into signingProperties: Attributes
        var configWrapper = Attributes()
        configWrapper.set(key: AWSMessageSigner.signingConfigKey, value: signingConfig)
        // Sign empty payload
        let signingResult = try await signer.signEvent(payload: .init(),
                                                       previousSignature: previousSignature,
                                                       signingProperties: configWrapper)
        return signingResult.output
    }
}
