package software.amazon.smithy.aws.swift.codegen.customization.glacier

import software.amazon.smithy.aws.swift.codegen.middleware.MutateHeadersMiddleware
import software.amazon.smithy.aws.swift.codegen.sdkId
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.expectShape

/**
 * Adds a middleware that sets the "X-Amz-Glacier-Version" header to the service model version for all requests
 * See https://docs.aws.amazon.com/amazonglacier/latest/dev/api-common-request-headers.html
 */
class GlacierAddVersionHeader : SwiftIntegration {

    override fun enabledForService(model: Model, settings: SwiftSettings) =
        model.expectShape<ServiceShape>(settings.service).sdkId.equals("Glacier", ignoreCase = true)

    override fun customizeMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operationShape: OperationShape,
        operationMiddleware: OperationMiddleware
    ) {
        operationMiddleware.appendMiddleware(
            operationShape,
            MutateHeadersMiddleware(
                extraHeaders = mapOf(
                    "X-Amz-Glacier-Version" to ctx.model.expectShape<ServiceShape>(ctx.settings.service).version
                )
            )
        )
    }
}
