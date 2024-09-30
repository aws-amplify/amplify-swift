/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.awsjson

import software.amazon.smithy.aws.swift.codegen.AWSHTTPBindingProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.middleware.AWSXAmzTargetMiddleware
import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.ContentTypeMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputBodyMiddleware

class AWSJSON1_0ProtocolGenerator : AWSHTTPBindingProtocolGenerator(AWSJSONCustomizations()) {
    override val defaultContentType = "application/x-amz-json-1.0"
    override val protocol: ShapeId = AwsJson1_0Trait.ID
    override val shouldRenderEncodableConformance: Boolean = true
    override val testsToIgnore = setOf(
        "SDKAppliedContentEncoding_awsJson1_0",
        "SDKAppendsGzipAndIgnoresHttpProvidedEncoding_awsJson1_0",
    )
    override fun getProtocolHttpBindingResolver(ctx: ProtocolGenerator.GenerationContext, defaultContentType: String):
        HttpBindingResolver = AWSJSONHttpBindingResolver(ctx, defaultContentType)

    override fun addProtocolSpecificMiddleware(ctx: ProtocolGenerator.GenerationContext, operation: OperationShape) {
        super.addProtocolSpecificMiddleware(ctx, operation)

        operationMiddleware.appendMiddleware(operation, AWSXAmzTargetMiddleware(ctx.model, ctx.symbolProvider, ctx.service))
        // Original instance of OperationInputBodyMiddleware checks if there is an HTTP Body, but for AWSJson protocols
        // we always need to have an InputBodyMiddleware
        operationMiddleware.removeMiddleware(operation, "OperationInputBodyMiddleware")
        operationMiddleware.appendMiddleware(operation, OperationInputBodyMiddleware(ctx.model, ctx.symbolProvider, true))

        val resolver = getProtocolHttpBindingResolver(ctx, defaultContentType)
        operationMiddleware.removeMiddleware(operation, "ContentTypeMiddleware")
        operationMiddleware.appendMiddleware(operation, ContentTypeMiddleware(ctx.model, ctx.symbolProvider, resolver.determineRequestContentType(operation), true))
    }
}
