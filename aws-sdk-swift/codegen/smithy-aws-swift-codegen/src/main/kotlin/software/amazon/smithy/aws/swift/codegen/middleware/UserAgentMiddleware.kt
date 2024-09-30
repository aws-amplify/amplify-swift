/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.middleware

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable

class UserAgentMiddleware(val settings: SwiftSettings) : MiddlewareRenderable {

    override val name = "UserAgentMiddleware"

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val params = middlewareParamsString(writer)
        val input = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
        val output = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
        writer.write(
            "\$N<\$N, \$N>($params)",
            AWSClientRuntimeTypes.Core.UserAgentMiddleware,
            input,
            output
        )
    }

    private fun middlewareParamsString(writer: SwiftWriter): String {
        return writer.format(
            "serviceID: serviceName, version: \$S, config: config",
            settings.moduleVersion,
        )
    }
}
