package software.amazon.smithy.aws.swift.codegen.middleware

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.model.expectShape

class GlacierAccountIdMiddleware(private val model: Model, private val symbolProvider: SymbolProvider) : MiddlewareRenderable {
    override val name = "GlacierAccountIdAutoFill"

    override fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        val accountId = model.expectShape<StructureShape>(op.input.get()).members().first { it.memberName.lowercase() == "accountid" }

        writer.write(
            """
            builder.interceptors.addModifyBeforeSerialization { context in
                let input = context.getInput()
                guard let accountId = input.${accountId.memberName}, !accountId.isEmpty else {
                    var copiedInput = input
                    copiedInput.${accountId.memberName} = "-"
                    context.updateInput(updated: copiedInput)
                    return
                }
            }
            """.trimIndent()
        )
    }
}
