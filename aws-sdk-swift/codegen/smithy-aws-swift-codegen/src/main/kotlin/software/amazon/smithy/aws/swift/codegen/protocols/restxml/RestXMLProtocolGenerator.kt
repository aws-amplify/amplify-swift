/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.restxml

import software.amazon.smithy.aws.swift.codegen.AWSHTTPBindingProtocolGenerator
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class RestXMLProtocolGenerator : AWSHTTPBindingProtocolGenerator(RestXMLCustomizations()) {
    override val defaultContentType: String = "application/xml"
    override val protocol: ShapeId = RestXmlTrait.ID
    override val testsToIgnore: Set<String> = setOf(
        "S3DefaultAddressing", // can leave disabled, pre-endpoints 2.0
        "S3VirtualHostAddressing", // can leave disabled, pre-endpoints 2.0
        "S3VirtualHostDualstackAddressing", // can leave disabled, pre-endpoints 2.0
        "S3VirtualHostAccelerateAddressing", // can leave disabled, pre-endpoints 2.0
        "S3VirtualHostDualstackAccelerateAddressing", // can leave disabled, pre-endpoints 2.0
        "S3OperationAddressingPreferred", // can leave disabled, pre-endpoints 2.0
        "S3EscapeObjectKeyInUriLabel", // moved to s3-tests.smithy
        "S3EscapePathObjectKeyInUriLabel", // moved to s3-tests.smithy
        "SDKAppliedContentEncoding_restXml", // not implemented yet (request compression)
        "SDKAppendedGzipAfterProvidedEncoding_restXml", // not implemented yet (request compression)
        "S3PreservesEmbeddedDotSegmentInUriLabel", // moved to s3-tests.smithy
        "S3PreservesLeadingDotSegmentInUriLabel", // moved to s3-tests.smithy
    )

    override fun generateDeserializers(ctx: ProtocolGenerator.GenerationContext) {
        super.generateDeserializers(ctx)
        val errorShapes = resolveErrorShapes(ctx)
        for (shape in errorShapes) {
            renderCodableExtension(ctx, shape)
        }
    }
}
