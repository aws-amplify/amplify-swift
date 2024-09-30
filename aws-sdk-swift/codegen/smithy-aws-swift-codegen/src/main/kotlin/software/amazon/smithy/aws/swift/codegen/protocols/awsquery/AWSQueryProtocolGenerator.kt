/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.awsquery

import software.amazon.smithy.aws.swift.codegen.AWSHTTPBindingProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.FormURLHttpBindingResolver
import software.amazon.smithy.aws.traits.protocols.AwsQueryTrait
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.ContentTypeMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputBodyMiddleware

open class AWSQueryProtocolGenerator : AWSHTTPBindingProtocolGenerator(AWSQueryCustomizations()) {
    override val defaultContentType = "application/x-www-form-urlencoded"
    override val protocol: ShapeId = AwsQueryTrait.ID

    override fun getProtocolHttpBindingResolver(ctx: ProtocolGenerator.GenerationContext, defaultContentType: String):
        HttpBindingResolver = FormURLHttpBindingResolver(ctx, defaultContentType)

    override val shouldRenderEncodableConformance = true
    override val testsToIgnore = setOf(
        "SDKAppliedContentEncoding_awsQuery",
        "SDKAppendsGzipAndIgnoresHttpProvidedEncoding_awsQuery",
    )

    override fun addProtocolSpecificMiddleware(ctx: ProtocolGenerator.GenerationContext, operation: OperationShape) {
        super.addProtocolSpecificMiddleware(ctx, operation)
        // Original instance of OperationInputBodyMiddleware checks if there is an HTTP Body, but for AWSQuery
        // we always need to have an InputBodyMiddleware
        operationMiddleware.removeMiddleware(operation, "OperationInputBodyMiddleware")
        operationMiddleware.appendMiddleware(operation, OperationInputBodyMiddleware(ctx.model, ctx.symbolProvider, true))

        val resolver = getProtocolHttpBindingResolver(ctx, defaultContentType)
        operationMiddleware.removeMiddleware(operation, "ContentTypeMiddleware")
        operationMiddleware.appendMiddleware(operation, ContentTypeMiddleware(ctx.model, ctx.symbolProvider, resolver.determineRequestContentType(operation), true))
    }
}
