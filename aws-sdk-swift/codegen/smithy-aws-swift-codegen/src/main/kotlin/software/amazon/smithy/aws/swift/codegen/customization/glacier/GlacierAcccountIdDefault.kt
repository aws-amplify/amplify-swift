package software.amazon.smithy.aws.swift.codegen.customization.glacier

import software.amazon.smithy.aws.swift.codegen.middleware.GlacierAccountIdMiddleware
import software.amazon.smithy.aws.swift.codegen.sdkId
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.expectShape

/**
 * Adds a middleware for Glacier to autofill accountId when not set
 * See: https://github.com/awslabs/aws-sdk-swift/issues/207
 */
class GlacierAccountIdDefault : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean =
        model.expectShape<ServiceShape>(settings.service).sdkId.equals("Glacier", ignoreCase = true)

    override fun customizeMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operationShape: OperationShape,
        operationMiddleware: OperationMiddleware
    ) {
        val input = operationShape.input.orElse(null)?.let { ctx.model.expectShape<StructureShape>(it) }
        val needsAccountIdMiddleware = input?.memberNames?.any { it.lowercase() == "accountid" } ?: false
        if (needsAccountIdMiddleware) {
            operationMiddleware.prependMiddleware(
                operationShape,
                GlacierAccountIdMiddleware(ctx.model, ctx.symbolProvider)
            )
        }
    }
}
