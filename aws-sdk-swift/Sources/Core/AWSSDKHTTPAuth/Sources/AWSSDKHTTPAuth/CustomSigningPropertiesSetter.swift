//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import enum Smithy.ClientError
import enum SmithyIdentityAPI.FlowType
import enum SmithyHTTPAuthAPI.AWSSignedBodyHeader
import enum SmithyHTTPAuthAPI.SigningPropertyKeys
import struct Smithy.Attributes

// Service-specific signing properties customization setter.
public class CustomSigningPropertiesSetter {
    // Services that require signing properties customizations.
    private let servicesWithCustomizations = ["S3", "Glacier", "S3 Control"]
    // List of services that use signed body heaader.
    private let usesSignedBodyHeader = ["S3", "Glacier", "S3 Control"]
    // Map of service::operation that use unsigned body for presign URL flow.
    private let forceUnsignedBodyForPresigningURL = [
        "S3": ["getObject", "putObject"]
    ]

    public init() {}

    public func setServiceSpecificSigningProperties(
        signingProperties: inout Attributes,
        context: Context
    ) throws {
        guard servicesWithCustomizations.contains(context.getServiceName()) else {
            return
        }
        guard let operationName = context.getOperation() else {
            throw ClientError.authError("Missing operation name in middleware context.")
        }
        let serviceName = context.getServiceName()
        // Set unsignedBody flag
        let shouldForceUnsignedBody = shouldForceUnsignedBody(
            flow: context.getFlowType(),
            serviceName: serviceName,
            opName: operationName
        )
        let unsignedBody =
            (signingProperties.get(key: SigningPropertyKeys.unsignedBody) ?? false) || shouldForceUnsignedBody
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: unsignedBody)

        // Set signedBodyHeader flag
        let useSignedBodyHeader = usesSignedBodyHeader.contains(serviceName) && !unsignedBody
        signingProperties.set(
            key: SigningPropertyKeys.signedBodyHeader,
            value: useSignedBodyHeader ? .contentSha256 : AWSSignedBodyHeader.none
        )

        // Set flags in SigningFlags object (S3 customizations)
        setS3SpecificFlags(signingProperties: &signingProperties, serviceName: serviceName)
    }

    // MARK: - HELPERS

    /*
     * Determines whether to force an unsigned body based on the service name, operation name, and flow type.
     * - Parameters:
     *   - flow: The type of flow (e.g., presigning a URL, presigning request, normal).
     *   - serviceName: The name of the service (e.g., "S3").
     *   - opName: The name of the operation (e.g., "GetObject").
     * - Returns: A Boolean indicating whether to force an unsigned body for the request.
     */
    private func shouldForceUnsignedBody(flow: FlowType, serviceName: String, opName: String) -> Bool {
        let serviceQualifies = forceUnsignedBodyForPresigningURL.keys.contains(serviceName)
        return serviceQualifies
        && (flow == .PRESIGN_URL)
        && forceUnsignedBodyForPresigningURL[serviceName]!.contains(opName)
    }

    // Sets S3-specific flags on the signing properties.
    private func setS3SpecificFlags(signingProperties: inout Attributes, serviceName: String) {
        let serviceIsS3 = serviceName == "S3"
        // Set useDoubleURIEncode to false IFF service is S3
        signingProperties.set(key: SigningPropertyKeys.useDoubleURIEncode, value: !serviceIsS3)
        // Set shouldNormalizeURIPath to false IFF service is S3
        signingProperties.set(key: SigningPropertyKeys.shouldNormalizeURIPath, value: !serviceIsS3)
    }
}
