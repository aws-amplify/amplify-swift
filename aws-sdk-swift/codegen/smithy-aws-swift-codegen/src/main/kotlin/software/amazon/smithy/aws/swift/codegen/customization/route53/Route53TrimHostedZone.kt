package software.amazon.smithy.aws.swift.codegen.customization.route53

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.HttpLabelTrait
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait

class Route53TrimHostedZone : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        return model.expectShape<ServiceShape>(settings.service).isRoute53
    }

    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        return ModelTransformer.create().mapShapes(model) {
            if (isHostId(it)) {
                (it as MemberShape).toBuilder().addTrait(TrimHostedZone()).build()
            } else {
                it
            }
        }
    }

    override fun customizeMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operationShape: OperationShape,
        operationMiddleware: OperationMiddleware
    ) {
        val inputShape = MiddlewareShapeUtils.inputShape(ctx.model, operationShape)
        val hostedZoneMember = inputShape.members().find { it.hasTrait<TrimHostedZone>() }
        if (hostedZoneMember != null) {
            operationMiddleware.prependMiddleware(operationShape, TrimHostedZoneURLPathMiddlewareRenderable(ctx.model, ctx.symbolProvider))
        }
    }

    private fun isHostId(shape: Shape): Boolean {
        return (shape is MemberShape && shape.target == ShapeId.from("com.amazonaws.route53#ResourceId")) && shape.hasTrait<HttpLabelTrait>()
    }
}
