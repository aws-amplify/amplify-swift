package software.amazon.smithy.aws.swift.codegen.customization.route53

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait

class TrimHostedZoneURLPathMiddlewareRenderable(
    val model: Model,
    val symbolProvider: SymbolProvider
) : MiddlewareRenderable {
    override val name = "Route53TrimHostedZoneMiddleware"

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputShape = model.expectShape<StructureShape>(op.inputShape)
        val hostedZoneIDMember = inputShape.members().first { it.hasTrait<TrimHostedZone>() }
        val hostedZoneIDKeyPath = ctx.symbolProvider.toMemberName(hostedZoneIDMember)
        val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, model, op)
        val outputSymbol = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, model, op)
        writer.write(
            "\$N<\$N, \$N>(\\.\$L)",
            AWSClientRuntimeTypes.Core.Route53TrimHostedZoneMiddleware,
            inputSymbol,
            outputSymbol,
            hostedZoneIDKeyPath
        )
    }
}
