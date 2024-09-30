package software.amazon.smithy.aws.swift.codegen.customization.machinelearning

import software.amazon.smithy.aws.swift.codegen.middleware.PredictInputEndpointURLHostMiddlewareRenderable
import software.amazon.smithy.aws.swift.codegen.middleware.handlers.PredictInputEndpointURLHostMiddlewareHandler
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.core.toProtocolGenerationContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.utils.ModelFileUtils

internal val ENABLED_OPERATIONS: Map<String, Set<String>> = mapOf(
    "com.amazonaws.machinelearning#AmazonML_20141212" to setOf(
        "com.amazonaws.machinelearning#Predict"
    )
)

class PredictEndpointIntegration(private val enabledOperations: Map<String, Set<String>> = ENABLED_OPERATIONS) : SwiftIntegration {

    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        val currentServiceId = model.expectShape<ServiceShape>(settings.service).id.toString()
        return enabledOperations.keys.contains(currentServiceId)
    }
    override fun writeAdditionalFiles(ctx: SwiftCodegenContext, protoCtx: ProtocolGenerator.GenerationContext, delegator: SwiftDelegator) {
        val serviceShape = ctx.model.expectShape<ServiceShape>(ctx.settings.service)
        val protocolGeneratorContext = ctx.toProtocolGenerationContext(serviceShape, delegator)?.let { it } ?: run { return }
        val service = ctx.model.expectShape<ServiceShape>(ctx.settings.service)
        val operationsToGenerate = enabledOperations.getOrDefault(service.id.toString(), setOf())

        operationsToGenerate.forEach { operation ->
            val op = ctx.model.expectShape<OperationShape>(operation)
            val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
            val outputSymbol = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
            val outputErrorSymbol = MiddlewareShapeUtils.outputErrorSymbol(op)

            val inputType = op.input.get()
            val filename = ModelFileUtils.filename(ctx.settings, "$inputType+EndpointURLHostMiddleware")
            delegator.useFileWriter(filename) { writer ->
                val predictMiddleware = PredictInputEndpointURLHostMiddlewareHandler(writer, protocolGeneratorContext, inputSymbol, outputSymbol, outputErrorSymbol)
                MiddlewareGenerator(writer, predictMiddleware).generate()
            }
        }
    }

    override fun customizeMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operationShape: OperationShape,
        operationMiddleware: OperationMiddleware
    ) {
        if (enabledOperations.values.contains(setOf(operationShape.id.toString()))) {
            operationMiddleware.removeMiddleware(operationShape, "OperationInputUrlHostMiddleware")
            operationMiddleware.appendMiddleware(operationShape, PredictInputEndpointURLHostMiddlewareRenderable())
        }
    }
}
