package software.amazon.smithy.aws.swift.codegen.customization

import software.amazon.smithy.aws.swift.codegen.middleware.MutateHeadersMiddleware
import software.amazon.smithy.aws.traits.protocols.AwsQueryCompatibleTrait
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.hasTrait

/**
 * Send an extra `x-amzn-query-mode` header with a value of `true` for services which have the [AwsQueryCompatibleTrait] applied.
 */
class AwsQueryModeCustomization : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean =
        model
            .getShape(settings.service)
            .get()
            .hasTrait<AwsQueryCompatibleTrait>()

    private val awsQueryModeHeaderMiddleware = MutateHeadersMiddleware(
        extraHeaders = mapOf("x-amzn-query-mode" to "true")
    )

    override fun customizeMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operationShape: OperationShape,
        operationMiddleware: OperationMiddleware
    ) {
        operationMiddleware.appendMiddleware(operationShape, awsQueryModeHeaderMiddleware)
    }
}
