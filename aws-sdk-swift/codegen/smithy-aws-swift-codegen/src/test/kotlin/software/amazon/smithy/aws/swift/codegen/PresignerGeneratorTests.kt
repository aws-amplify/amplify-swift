package software.amazon.smithy.aws.swift.codegen
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
class PresignerGeneratorTests {
    @Test
    fun `001 presignable on getFooInput`() {
        val context = setupTests("awsrestjson1/presignable.smithy", "smithy.swift.traits#Example")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/models/GetFooInput+Presigner.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension GetFooInput {
    public func presign(config: ExampleClient.ExampleClientConfiguration, expiration: Foundation.TimeInterval) async throws -> SmithyHTTPAPI.HTTPRequest? {
        let serviceName = "example"
        let input = self
        let client: (SmithyHTTPAPI.HTTPRequest, Smithy.Context) async throws -> SmithyHTTPAPI.HTTPResponse = { (_, _) in
            throw Smithy.ClientError.unknownError("No HTTP client configured for presigned request")
        }
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .get)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "getFoo")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withPartitionID(value: config.partitionID)
                      .withAuthSchemes(value: config.authSchemes ?? [])
                      .withAuthSchemeResolver(value: config.authSchemeResolver)
                      .withUnsignedPayloadTrait(value: false)
                      .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
                      .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
                      .withFlowType(value: .PRESIGN_REQUEST)
                      .withExpiration(value: expiration)
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4a")
                      .withRegion(value: config.region)
                      .withSigningName(value: "example-signing-name")
                      .withSigningRegion(value: config.signingRegion)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<GetFooInput, GetFooOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<GetFooInput, GetFooOutput>(GetFooInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<GetFooInput, GetFooOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<GetFooOutput>(GetFooOutput.httpOutput(from:), GetFooOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<GetFooInput, GetFooOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<GetFooOutput>())
        let endpointParams = EndpointParams()
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<GetFooOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: ${'$'}0) }, endpointParams: endpointParams))
        builder.interceptors.add(AWSClientRuntime.UserAgentMiddleware<GetFooInput, GetFooOutput>(serviceID: serviceName, version: "1.0.0", config: config))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<GetFooOutput>())
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "Example")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "GetFoo")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.presignRequest(input: input)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `002 presignable on postFooInput`() {
        val context = setupTests("awsrestjson1/presignable.smithy", "smithy.swift.traits#Example")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/models/PostFooInput+Presigner.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension PostFooInput {
    public func presign(config: ExampleClient.ExampleClientConfiguration, expiration: Foundation.TimeInterval) async throws -> SmithyHTTPAPI.HTTPRequest? {
        let serviceName = "example"
        let input = self
        let client: (SmithyHTTPAPI.HTTPRequest, Smithy.Context) async throws -> SmithyHTTPAPI.HTTPResponse = { (_, _) in
            throw Smithy.ClientError.unknownError("No HTTP client configured for presigned request")
        }
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "postFoo")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withPartitionID(value: config.partitionID)
                      .withAuthSchemes(value: config.authSchemes ?? [])
                      .withAuthSchemeResolver(value: config.authSchemeResolver)
                      .withUnsignedPayloadTrait(value: false)
                      .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
                      .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
                      .withFlowType(value: .PRESIGN_REQUEST)
                      .withExpiration(value: expiration)
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4a")
                      .withRegion(value: config.region)
                      .withSigningName(value: "example-signing-name")
                      .withSigningRegion(value: config.signingRegion)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<PostFooInput, PostFooOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<PostFooInput, PostFooOutput>(PostFooInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<PostFooInput, PostFooOutput>())
        builder.interceptors.add(ClientRuntime.ContentTypeMiddleware<PostFooInput, PostFooOutput>(contentType: "application/json"))
        builder.serialize(ClientRuntime.BodyMiddleware<PostFooInput, PostFooOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: PostFooInput.write(value:to:)))
        builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<PostFooInput, PostFooOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<PostFooOutput>(PostFooOutput.httpOutput(from:), PostFooOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<PostFooInput, PostFooOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<PostFooOutput>())
        let endpointParams = EndpointParams()
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<PostFooOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: ${'$'}0) }, endpointParams: endpointParams))
        builder.interceptors.add(AWSClientRuntime.UserAgentMiddleware<PostFooInput, PostFooOutput>(serviceID: serviceName, version: "1.0.0", config: config))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<PostFooOutput>())
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "Example")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "PostFoo")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.presignRequest(input: input)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `003 presignable on putFooInput`() {
        val context = setupTests("awsrestjson1/presignable.smithy", "smithy.swift.traits#Example")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/models/PutFooInput+Presigner.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension PutFooInput {
    public func presign(config: ExampleClient.ExampleClientConfiguration, expiration: Foundation.TimeInterval) async throws -> SmithyHTTPAPI.HTTPRequest? {
        let serviceName = "example"
        let input = self
        let client: (SmithyHTTPAPI.HTTPRequest, Smithy.Context) async throws -> SmithyHTTPAPI.HTTPResponse = { (_, _) in
            throw Smithy.ClientError.unknownError("No HTTP client configured for presigned request")
        }
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .put)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "putFoo")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withPartitionID(value: config.partitionID)
                      .withAuthSchemes(value: config.authSchemes ?? [])
                      .withAuthSchemeResolver(value: config.authSchemeResolver)
                      .withUnsignedPayloadTrait(value: false)
                      .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
                      .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
                      .withFlowType(value: .PRESIGN_REQUEST)
                      .withExpiration(value: expiration)
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4a")
                      .withRegion(value: config.region)
                      .withSigningName(value: "example-signing-name")
                      .withSigningRegion(value: config.signingRegion)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<PutFooInput, PutFooOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<PutFooInput, PutFooOutput>(PutFooInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<PutFooInput, PutFooOutput>())
        builder.interceptors.add(ClientRuntime.ContentTypeMiddleware<PutFooInput, PutFooOutput>(contentType: "application/json"))
        builder.serialize(ClientRuntime.BodyMiddleware<PutFooInput, PutFooOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: PutFooInput.write(value:to:)))
        builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<PutFooInput, PutFooOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<PutFooOutput>(PutFooOutput.httpOutput(from:), PutFooOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<PutFooInput, PutFooOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<PutFooOutput>())
        let endpointParams = EndpointParams()
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<PutFooOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: ${'$'}0) }, endpointParams: endpointParams))
        builder.interceptors.add(AWSClientRuntime.UserAgentMiddleware<PutFooInput, PutFooOutput>(serviceID: serviceName, version: "1.0.0", config: config))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<PutFooOutput>())
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "Example")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "PutFoo")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.presignRequest(input: input)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `004 presignable on S3`() {
        val context = setupTests("presign-urls-s3.smithy", "com.amazonaws.s3#AmazonS3")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/models/PutObjectInput+Presigner.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension PutObjectInput {
    public func presign(config: S3Client.S3ClientConfiguration, expiration: Foundation.TimeInterval) async throws -> SmithyHTTPAPI.HTTPRequest? {
        let serviceName = "S3"
        let input = self
        let client: (SmithyHTTPAPI.HTTPRequest, Smithy.Context) async throws -> SmithyHTTPAPI.HTTPResponse = { (_, _) in
            throw Smithy.ClientError.unknownError("No HTTP client configured for presigned request")
        }
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .put)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "putObject")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withPartitionID(value: config.partitionID)
                      .withAuthSchemes(value: config.authSchemes ?? [])
                      .withAuthSchemeResolver(value: config.authSchemeResolver)
                      .withUnsignedPayloadTrait(value: false)
                      .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
                      .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
                      .withFlowType(value: .PRESIGN_REQUEST)
                      .withExpiration(value: expiration)
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4a")
                      .withRegion(value: config.region)
                      .withSigningName(value: "s3")
                      .withSigningRegion(value: config.signingRegion)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<PutObjectInput, PutObjectOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<PutObjectInput, PutObjectOutput>(PutObjectInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<PutObjectInput, PutObjectOutput>())
        builder.interceptors.add(ClientRuntime.ContentTypeMiddleware<PutObjectInput, PutObjectOutput>(contentType: "application/json"))
        builder.serialize(ClientRuntime.BodyMiddleware<PutObjectInput, PutObjectOutput, SmithyXML.Writer>(rootNodeInfo: "PutObjectInput", inputWritingClosure: PutObjectInput.write(value:to:)))
        builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<PutObjectInput, PutObjectOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<PutObjectOutput>(PutObjectOutput.httpOutput(from:), PutObjectOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<PutObjectInput, PutObjectOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<PutObjectOutput>())
        let endpointParams = EndpointParams()
        context.attributes.set(key: Smithy.AttributeKey<EndpointParams>(name: "EndpointParams"), value: endpointParams)
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<PutObjectOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: ${'$'}0) }, endpointParams: endpointParams))
        builder.interceptors.add(AWSClientRuntime.UserAgentMiddleware<PutObjectInput, PutObjectOutput>(serviceID: serviceName, version: "1.0.0", config: config))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<PutObjectOutput>())
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "S3")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "PutObject")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.presignRequest(input: input)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestJson1Trait.ID)
        val presigner = PresignerGenerator()
        val generator = AWSRestJson1ProtocolGenerator()
        val codegenContext = GenerationContext(context.ctx.model, context.ctx.symbolProvider, context.ctx.settings, context.manifest, generator)
        val protocolGenerationContext = ProtocolGenerator.GenerationContext(context.ctx.settings, context.ctx.model, context.ctx.service, context.ctx.symbolProvider, listOf(), RestJson1Trait.ID, context.ctx.delegator)
        codegenContext.protocolGenerator?.initializeMiddleware(context.ctx)
        presigner.writeAdditionalFiles(codegenContext, protocolGenerationContext, context.ctx.delegator)
        context.ctx.delegator.flushWriters()
        return context
    }
}
