package software.amazon.smithy.aws.swift.codegen.customization.presignable

import software.amazon.smithy.aws.swift.codegen.AWSAuthUtils
import software.amazon.smithy.aws.swift.codegen.AWSServiceConfig
import software.amazon.smithy.aws.swift.codegen.PresignableOperation
import software.amazon.smithy.aws.swift.codegen.customization.InputTypeGETQueryItemMiddleware
import software.amazon.smithy.aws.swift.codegen.customization.PutObjectPresignedURLMiddleware
import software.amazon.smithy.aws.swift.codegen.middleware.AmzSdkInvocationIdMiddleware
import software.amazon.smithy.aws.swift.codegen.middleware.AmzSdkRequestMiddleware
import software.amazon.smithy.aws.swift.codegen.middleware.InputTypeGETQueryItemMiddlewareRenderable
import software.amazon.smithy.aws.swift.codegen.middleware.PutObjectPresignedURLMiddlewareRenderable
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.core.toProtocolGenerationContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareExecutionGenerator
import software.amazon.smithy.swift.codegen.middleware.MiddlewareExecutionGenerator.Companion.ContextAttributeCodegenFlowType.PRESIGN_URL
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.swiftmodules.FoundationTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import software.amazon.smithy.swift.codegen.utils.ModelFileUtils

internal val PRESIGNABLE_URL_OPERATIONS: Map<String, Set<String>> = mapOf(
    "com.amazonaws.polly#Parrot_v1" to setOf(
        "com.amazonaws.polly#SynthesizeSpeech"
    ),
    "com.amazonaws.s3#AmazonS3" to setOf(
        "com.amazonaws.s3#GetObject",
        "com.amazonaws.s3#PutObject",
    )
)

class PresignableUrlIntegration(private val presignedOperations: Map<String, Set<String>> = PRESIGNABLE_URL_OPERATIONS) : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        val currentServiceId = model.expectShape<ServiceShape>(settings.service).id.toString()

        return presignedOperations.keys.contains(currentServiceId)
    }

    override fun writeAdditionalFiles(ctx: SwiftCodegenContext, protocolGenerationContext: ProtocolGenerator.GenerationContext, delegator: SwiftDelegator) {
        val service = ctx.model.expectShape<ServiceShape>(ctx.settings.service)

        if (!AWSAuthUtils.isSupportedAuthentication(ctx.model, service)) return

        val operationsToGenerate = presignedOperations.getOrDefault(service.id.toString(), setOf())

        val presignOperations = service.allOperations
            .map { ctx.model.expectShape<OperationShape>(it) }
            .filter { operationShape -> operationsToGenerate.contains(operationShape.id.toString()) }
            .map { operationShape ->
                check(AWSAuthUtils.hasSigV4AuthScheme(ctx.model, service, operationShape)) { "Operation does not have valid auth trait" }
                PresignableOperation(service.id.toString(), operationShape.id.toString())
            }
        presignOperations.forEach { presignableOperation ->
            val op = ctx.model.expectShape<OperationShape>(presignableOperation.operationId)
            val inputType = op.input.get().getName()
            val outputType = op.output.get().getName()
            val filename = ModelFileUtils.filename(ctx.settings, "$inputType+Presigner")
            delegator.useFileWriter(filename) { writer ->
                val serviceConfig = AWSServiceConfig(writer, protocolGenerationContext)
                renderPresigner(writer, ctx, delegator, op, inputType, outputType, serviceConfig)
            }
            // Expose presign-URL as a method for service client object
            val symbol = protocolGenerationContext.symbolProvider.toSymbol(protocolGenerationContext.service)
            val clientFilename = "Sources/${ctx.settings.moduleName}/${symbol.name}.swift"
            protocolGenerationContext.delegator.useFileWriter(clientFilename) { writer ->
                renderPresignURLAPIInServiceClient(writer, symbol.name, op, inputType)
            }
            when (presignableOperation.operationId) {
                "com.amazonaws.s3#GetObject", "com.amazonaws.polly#SynthesizeSpeech" -> {
                    renderMiddlewareClassForQueryString(ctx, delegator, op)
                }
                "com.amazonaws.s3#PutObject" -> {
                    renderMiddlewareClassForPutObject(ctx, delegator, op)
                }
            }
        }
    }

    private fun renderPresigner(
        writer: SwiftWriter,
        ctx: SwiftCodegenContext,
        delegator: SwiftDelegator,
        op: OperationShape,
        inputType: String,
        outputType: String,
        serviceConfig: AWSServiceConfig
    ) {
        val serviceShape = ctx.model.expectShape<ServiceShape>(ctx.settings.service)
        val protocolGenerator = ctx.protocolGenerator?.let { it } ?: run { return }
        val protocolGeneratorContext = ctx.toProtocolGenerationContext(serviceShape, delegator)?.let { it } ?: run { return }
        val operationMiddleware = resolveOperationMiddleware(protocolGenerator, protocolGeneratorContext, op)

        val httpBindingResolver = protocolGenerator.getProtocolHttpBindingResolver(protocolGeneratorContext, protocolGenerator.defaultContentType)

        writer.openBlock("extension $inputType {", "}") {
            writer.openBlock(
                "public func presignURL(config: \$L, expiration: \$N) async throws -> \$T {", "}",
                serviceConfig.typeName,
                FoundationTypes.TimeInterval,
                FoundationTypes.URL,
            ) {
                writer.write("let serviceName = \"${ctx.settings.sdkId}\"")
                writer.write("let input = self")
                writer.openBlock(
                    "let client: (\$N, \$N) async throws -> \$N = { (_, _) in",
                    "}",
                    SmithyHTTPAPITypes.HTTPRequest,
                    SmithyTypes.Context,
                    SmithyHTTPAPITypes.HTTPResponse,
                ) {
                    writer.write("throw \$N.unknownError(\"No HTTP client configured for presigned request\")", SmithyTypes.ClientError)
                }

                val operationStackName = "operation"
                val generator = MiddlewareExecutionGenerator(
                    protocolGeneratorContext,
                    writer,
                    httpBindingResolver,
                    protocolGenerator.customizations,
                    operationMiddleware,
                    operationStackName,
                    ::overrideHttpMethod
                )
                generator.render(serviceShape, op, PRESIGN_URL) { writer, _ ->
                    writer.write("return nil")
                }

                writer.write("return try await op.presignRequest(input: input).endpoint.url")
            }
        }
    }

    private fun renderPresignURLAPIInServiceClient(
        writer: SwiftWriter,
        clientName: String,
        op: OperationShape,
        inputType: String
    ) {
        writer.apply {
            openBlock("extension $clientName {", "}") {
                val params = listOf("input: $inputType", format("expiration: \$N", FoundationTypes.TimeInterval))
                renderDocForPresignURLAPI(this, op, inputType)
                openBlock(
                    "public func presignedURLFor${op.toUpperCamelCase()}(${params.joinToString()}) async throws -> \$N {",
                    "}",
                    FoundationTypes.URL,
                ) {
                    write("let presignedURL = try await input.presignURL(config: config, expiration: expiration)")
                    openBlock("guard let presignedURL else {", "}") {
                        write("throw \$N.unknownError(\"Could not generate presigned URL for the operation ${op.toUpperCamelCase()}.\")", SmithyTypes.ClientError)
                    }
                    write("return presignedURL")
                }
            }
        }
    }

    private fun renderDocForPresignURLAPI(writer: SwiftWriter, op: OperationShape, inputType: String) {
        writer.apply {
            write("/// Presigns the URL for ${op.toUpperCamelCase()} operation with the given input object $inputType.")
            write("/// The presigned URL will be valid for the given expiration, in seconds.")
            write("///")
            write("/// Below is the documentation for ${op.toUpperCamelCase()} operation:")
            writeShapeDocs(op)
            write("///")
            write("/// - Parameter input: The input object for ${op.toUpperCamelCase()} operation used to construct request.")
            write("/// - Parameter expiration: The duration (in seconds) the presigned request will be valid for.")
            write("///")
            write("/// - Returns: `Foundation.URL`: The presigned URL for ${op.toUpperCamelCase()} operation.")
        }
    }

    private fun resolveOperationMiddleware(protocolGenerator: ProtocolGenerator, context: ProtocolGenerator.GenerationContext, op: OperationShape): OperationMiddleware {
        val inputSymbol = MiddlewareShapeUtils.inputSymbol(context.symbolProvider, context.model, op)
        val operationMiddlewareCopy = protocolGenerator.operationMiddleware.clone()
        operationMiddlewareCopy.removeMiddleware(op, "UserAgentMiddleware")
        operationMiddlewareCopy.removeMiddleware(op, "ContentTypeMiddleware")
        operationMiddlewareCopy.removeMiddleware(op, "OperationInputQueryItemMiddleware")
        operationMiddlewareCopy.removeMiddleware(op, "OperationInputHeadersMiddleware")
        operationMiddlewareCopy.removeMiddleware(op, "ContentLengthMiddleware")
        operationMiddlewareCopy.removeMiddleware(op, AmzSdkRequestMiddleware.NAME)
        operationMiddlewareCopy.removeMiddleware(op, AmzSdkInvocationIdMiddleware.NAME)

        when (op.id.toString()) {
            "com.amazonaws.s3#GetObject", "com.amazonaws.polly#SynthesizeSpeech" -> {
                operationMiddlewareCopy.removeMiddleware(op, "OperationInputBodyMiddleware")
                operationMiddlewareCopy.appendMiddleware(op, InputTypeGETQueryItemMiddlewareRenderable(inputSymbol))
            }
            "com.amazonaws.s3#PutObject" -> {
                operationMiddlewareCopy.removeMiddleware(op, "OperationInputBodyMiddleware")
                operationMiddlewareCopy.appendMiddleware(op, PutObjectPresignedURLMiddlewareRenderable())
            }
        }

        return operationMiddlewareCopy
    }

    private fun renderMiddlewareClassForQueryString(codegenContext: SwiftCodegenContext, delegator: SwiftDelegator, op: OperationShape) {

        val serviceShape = codegenContext.model.expectShape<ServiceShape>(codegenContext.settings.service)
        val ctx = codegenContext.toProtocolGenerationContext(serviceShape, delegator)?.let { it } ?: run { return }

        val opIndex = OperationIndex.of(ctx.model)
        val inputShape = opIndex.getInput(op).get()
        val outputShape = opIndex.getOutput(op).get()
        val operationErrorName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        val inputSymbol = ctx.symbolProvider.toSymbol(inputShape)
        val outputSymbol = ctx.symbolProvider.toSymbol(outputShape)
        val outputErrorSymbol = Symbol.builder().name(operationErrorName).build()
        val filename = ModelFileUtils.filename(ctx.settings, "${inputSymbol.name}+QueryItemMiddlewareForPresignUrl")
        val headerMiddlewareSymbol = Symbol.builder()
            .definitionFile(filename)
            .name(inputSymbol.name)
            .build()
        delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
            val queryItemMiddleware = InputTypeGETQueryItemMiddleware(
                ctx,
                inputSymbol,
                outputSymbol,
                outputErrorSymbol,
                inputShape,
                writer
            )
            MiddlewareGenerator(writer, queryItemMiddleware).generate()
        }
    }

    private fun renderMiddlewareClassForPutObject(codegenContext: SwiftCodegenContext, delegator: SwiftDelegator, op: OperationShape) {

        val serviceShape = codegenContext.model.expectShape<ServiceShape>(codegenContext.settings.service)
        val ctx = codegenContext.toProtocolGenerationContext(serviceShape, delegator)?.let { it } ?: run { return }

        val opIndex = OperationIndex.of(ctx.model)
        val inputShape = opIndex.getInput(op).get()
        val outputShape = opIndex.getOutput(op).get()
        val operationErrorName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        val inputSymbol = ctx.symbolProvider.toSymbol(inputShape)
        val outputSymbol = ctx.symbolProvider.toSymbol(outputShape)
        val outputErrorSymbol = Symbol.builder().name(operationErrorName).build()
        val filename = ModelFileUtils.filename(ctx.settings, "${inputSymbol.name}+QueryItemMiddlewareForPresignUrl")
        val headerMiddlewareSymbol = Symbol.builder()
            .definitionFile(filename)
            .name(inputSymbol.name)
            .build()
        delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
            val queryItemMiddleware = PutObjectPresignedURLMiddleware(
                inputSymbol,
                outputSymbol,
                outputErrorSymbol,
                writer
            )
            MiddlewareGenerator(writer, queryItemMiddleware).generate()
        }
    }

    private fun overrideHttpMethod(operation: OperationShape): String {
        return when (operation.id.toString()) {
            "com.amazonaws.s3#PutObject" -> "put"
            else -> "get"
        }
    }
}
