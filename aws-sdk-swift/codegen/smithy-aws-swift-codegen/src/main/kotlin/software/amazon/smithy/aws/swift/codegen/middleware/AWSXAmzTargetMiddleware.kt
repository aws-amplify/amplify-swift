/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.middleware

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes.AWSJSON.XAmzTargetMiddleware
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable

class AWSXAmzTargetMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val serviceShape: ServiceShape
) : MiddlewareRenderable {

    override val name = "AWSXAmzTargetMiddleware"

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        writer.write("\$N<$inputShapeName, $outputShapeName>(${middlewareParamsString(op)})", XAmzTargetMiddleware)
    }

    private fun middlewareParamsString(op: OperationShape): String {
        val xAmzTargetValue = xAmzTargetValue(serviceShape, op)
        return "xAmzTarget: \"${xAmzTargetValue}\""
    }

    private fun xAmzTargetValue(serviceShape: ServiceShape, op: OperationShape): String {
        return "${serviceShape.id.name}.${op.id.name}"
    }
}
