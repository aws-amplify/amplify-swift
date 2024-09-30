//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import enum SmithyHTTPAuthAPI.AWSSignedBodyHeader
import enum SmithyHTTPAuthAPI.SigningPropertyKeys
import protocol SmithyHTTPAuthAPI.AuthScheme
import protocol SmithyHTTPAuthAPI.Signer
import struct Smithy.Attributes

public struct SigV4AAuthScheme: AuthScheme {
    public let schemeID: String = "aws.auth#sigv4a"
    public let signer: Signer = AWSSigV4Signer()

    public init() {}

    public func customizeSigningProperties(signingProperties: Attributes, context: Context) throws -> Attributes {
        var updatedSigningProperties = signingProperties

        // Set signing algorithm flag
        updatedSigningProperties.set(key: SigningPropertyKeys.signingAlgorithm, value: .sigv4a)

        // Set bidirectional streaming flag
        updatedSigningProperties.set(
            key: SigningPropertyKeys.bidirectionalStreaming,
            value: context.isBidirectionalStreamingEnabled
        )

        // Set signing name and signing region flags
        updatedSigningProperties.set(key: SigningPropertyKeys.signingName, value: context.signingName)
        updatedSigningProperties.set(key: SigningPropertyKeys.signingRegion, value: context.signingRegion)

        // Set expiration flag
        //
        // Expiration is only used for presigning (presign request flow or presign URL flow).
        updatedSigningProperties.set(key: SigningPropertyKeys.expiration, value: context.expiration)

        // Set signature type flag
        //
        // AWSSignatureType.requestQueryParams is only used for presign URL flow.
        // Out of the AWSSignatureType enum cases, only two are used. .requestHeaders and .requestQueryParams.
        // .requestHeaders is the deafult signing used for AWS operations.
        let isPresignURLFlow = context.getFlowType() == .PRESIGN_URL
        updatedSigningProperties.set(
            key: SigningPropertyKeys.signatureType,
            value: isPresignURLFlow ? .requestQueryParams : .requestHeaders
        )

        // Set unsignedBody to true IFF operation had unsigned payload trait.
        let unsignedBody = context.hasUnsignedPayloadTrait()
        updatedSigningProperties.set(key: SigningPropertyKeys.unsignedBody, value: unsignedBody)

        // Set default values.
        updatedSigningProperties.set(key: SigningPropertyKeys.signedBodyHeader, value: AWSSignedBodyHeader.none)
        updatedSigningProperties.set(key: SigningPropertyKeys.useDoubleURIEncode, value: true)
        updatedSigningProperties.set(key: SigningPropertyKeys.shouldNormalizeURIPath, value: true)
        updatedSigningProperties.set(key: SigningPropertyKeys.omitSessionToken, value: false)

        // Set service-specific signing properties if needed.
        try CustomSigningPropertiesSetter().setServiceSpecificSigningProperties(
            signingProperties: &updatedSigningProperties,
            context: context
        )

        return updatedSigningProperties
    }
}
