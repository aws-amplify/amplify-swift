/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.restxml

import software.amazon.smithy.aws.swift.codegen.AWSHTTPProtocolCustomizations
import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable.ServiceErrorCustomRenderer
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class RestXMLCustomizations : AWSHTTPProtocolCustomizations() {

    override val baseErrorSymbol: Symbol = AWSClientRuntimeTypes.RestXML.RestXMLError

    private class S3Empty404Renderer : ServiceErrorCustomRenderer {

        override fun render(writer: SwiftWriter) {
            writer.openBlock(
                "if baseError.httpResponse.statusCode == .notFound && baseError.httpResponse.body.isEmpty {",
                "}"
            ) {
                writer.write("return try NotFound.makeError(baseError: baseError)")
            }
        }
    }

    override fun serviceErrorCustomRenderer(
        ctx: ProtocolGenerator.GenerationContext
    ): ServiceErrorCustomRenderer? {
        return S3Empty404Renderer().takeIf { shouldApplyS3ErrorCustomization(ctx) }
    }

    private fun shouldApplyS3ErrorCustomization(ctx: ProtocolGenerator.GenerationContext): Boolean {
        return serviceIsS3(ctx) && serviceHasNotFoundError(ctx)
    }

    private fun serviceIsS3(ctx: ProtocolGenerator.GenerationContext): Boolean {
        return ctx.service.id == ShapeId.from("com.amazonaws.s3#AmazonS3")
    }

    // This check is performed because S3 protocol tests do not define the NotFound modeled error,
    // and the protocol test will fail if it is undefined.
    private fun serviceHasNotFoundError(ctx: ProtocolGenerator.GenerationContext): Boolean {
        return ctx.model.getShape(ShapeId.from("com.amazonaws.s3#NotFound")).isPresent
    }
}
