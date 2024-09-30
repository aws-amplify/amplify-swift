package software.amazon.smithy.aws.swift.codegen.middleware

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable

class InputTypeGETQueryItemMiddlewareRenderable(inputSymbol: Symbol) : MiddlewareRenderable {

    override val name = "${inputSymbol.name}GETQueryItemMiddleware"

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String
    ) {
        super.renderSpecific(ctx, writer, op, operationStackName, "serialize")
    }

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        writer.write("$name()")
    }
}
