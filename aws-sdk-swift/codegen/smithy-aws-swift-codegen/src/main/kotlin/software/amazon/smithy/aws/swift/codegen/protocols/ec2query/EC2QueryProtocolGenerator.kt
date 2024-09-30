/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.ec2query

import software.amazon.smithy.aws.swift.codegen.AWSHTTPBindingProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.FormURLHttpBindingResolver
import software.amazon.smithy.aws.traits.protocols.Ec2QueryTrait
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.ContentTypeMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputBodyMiddleware

class EC2QueryProtocolGenerator : AWSHTTPBindingProtocolGenerator(EC2QueryCustomizations()) {
    override val defaultContentType = "application/x-www-form-urlencoded"
    override val protocol: ShapeId = Ec2QueryTrait.ID

    override fun getProtocolHttpBindingResolver(ctx: ProtocolGenerator.GenerationContext, contentType: String):
        HttpBindingResolver = FormURLHttpBindingResolver(ctx, contentType)

    override val shouldRenderEncodableConformance = true
    override val testsToIgnore = setOf(
        "SDKAppliedContentEncoding_ec2Query",
        "SDKAppendsGzipAndIgnoresHttpProvidedEncoding_ec2Query"
    )

    override fun addProtocolSpecificMiddleware(ctx: ProtocolGenerator.GenerationContext, operation: OperationShape) {
        super.addProtocolSpecificMiddleware(ctx, operation)
        // Original instance of OperationInputBodyMiddleware checks if there is an HTTP Body, but for Ec2Query
        // we always need to have an InputBodyMiddleware
        operationMiddleware.removeMiddleware(operation, "OperationInputBodyMiddleware")
        operationMiddleware.appendMiddleware(operation, OperationInputBodyMiddleware(ctx.model, ctx.symbolProvider, true))

        val resolver = getProtocolHttpBindingResolver(ctx, defaultContentType)
        operationMiddleware.removeMiddleware(operation, "ContentTypeMiddleware")
        operationMiddleware.appendMiddleware(operation, ContentTypeMiddleware(ctx.model, ctx.symbolProvider, resolver.determineRequestContentType(operation), true))
    }
}
