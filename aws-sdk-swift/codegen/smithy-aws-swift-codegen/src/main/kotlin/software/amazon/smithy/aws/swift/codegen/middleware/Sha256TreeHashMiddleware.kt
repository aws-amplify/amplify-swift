package software.amazon.smithy.aws.swift.codegen.middleware

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable

class Sha256TreeHashMiddleware(private val symbolProvider: SymbolProvider, private val model: Model) : MiddlewareRenderable {
    override val name = "Sha256TreeHashMiddleware"

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputShape = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op)
        val outputShape = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op)
        writer.write(
            "\$N<\$N, \$N>()",
            AWSClientRuntimeTypes.Core.Sha256TreeHashMiddleware,
            inputShape,
            outputShape
        )
    }
}
