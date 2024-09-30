/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */
package software.amazon.smithy.aws.swift.codegen.customization.s3

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.isStreaming

/**
 * Register interceptor to handle S3 error responses returned with an HTTP 200 status code.
 * see [aws-sdk-kotlin#199](https://github.com/awslabs/aws-sdk-kotlin/issues/199)
 * see [aws-sdk-swift#1113](https://github.com/awslabs/aws-sdk-swift/issues/1113)
 */
class S3ErrorWith200StatusIntegration : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean =
        model.expectShape<ServiceShape>(settings.service).isS3

    override fun customizeMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operationShape: OperationShape,
        operationMiddleware: OperationMiddleware,
    ) {
        // we don't know for sure what operations S3 does this on. Go customized this for only a select few
        // like CopyObject/UploadPartCopy/CompleteMultipartUpload but Rust hit it on additional operations
        // (DeleteObjects).
        // Instead of playing whack-a-mole broadly apply this interceptor to everything but streaming responses
        // which adds a small amount of overhead to response processing.
        val output = ctx.model.expectShape(operationShape.output.get())
        val outputIsNotAStreamingBlobShape = output.members().none {
            val targetShape = ctx.model.expectShape(it.target)
            val isBlob = it.isBlobShape || targetShape.isBlobShape
            val isStreaming = it.isStreaming || targetShape.isStreaming
            isBlob && isStreaming
        }

        if (outputIsNotAStreamingBlobShape) {
            operationMiddleware.appendMiddleware(operationShape, S3HandleError200ResponseMiddleware)
        }
    }
}

private object S3HandleError200ResponseMiddleware : MiddlewareRenderable {
    override val name = AWSClientRuntimeTypes.RestXML.S3.AWSS3ErrorWith200StatusXMLMiddleware.name

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputShape = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
        val outputShape = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
        writer.write(
            "\$N<\$N, \$N>()",
            AWSClientRuntimeTypes.RestXML.S3.AWSS3ErrorWith200StatusXMLMiddleware,
            inputShape,
            outputShape
        )
    }
}
