package software.amazon.smithy.aws.swift.codegen.middleware

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class MutateHeadersMiddleware(
    private val extraHeaders: Map<String, String> = emptyMap(),
    private val overrideHeaders: Map<String, String> = emptyMap(),
    private val addMissingHeaders: Map<String, String> = emptyMap(),
) : MiddlewareRenderable {
    override val name = "MutateHeaderMiddleware"

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
        val outputSymbol = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
        writer.write(
            "\$N<\$N, \$N>(${middlewareParamsString()})",
            ClientRuntimeTypes.Middleware.MutateHeadersMiddleware,
            inputSymbol,
            outputSymbol
        )
    }

    private fun middlewareParamsString(): String {
        val overrideHeadersString = overrideHeaders.entries.joinToString { "\"${it.key}\": \"${it.value}\"" }
        val extraHeadersString = extraHeaders.entries.joinToString { "\"${it.key}\": \"${it.value}\"" }
        val addMissingHeadersString = addMissingHeaders.entries.joinToString { "\"${it.key}\": \"${it.value}\"" }

        var parameters = mutableListOf<String>()
        if (overrideHeadersString.isNotEmpty()) {
            parameters.add("overrides: [$overrideHeadersString]")
        }
        if (extraHeadersString.isNotEmpty()) {
            parameters.add("additional: [$extraHeadersString]")
        }
        if (addMissingHeadersString.isNotEmpty()) {
            parameters.add("conditionallySet: [$addMissingHeadersString]")
        }
        return parameters.joinToString { it }
    }
}
