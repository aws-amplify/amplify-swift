//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import class AWSClientRuntime.AWSClientConfigDefaultsProvider
import class AWSClientRuntime.AmzSdkRequestMiddleware
import class AWSClientRuntime.DefaultAWSClientPlugin
import class ClientRuntime.ClientBuilder
import class ClientRuntime.DefaultClientPlugin
import class ClientRuntime.HttpClientConfiguration
import class ClientRuntime.OrchestratorBuilder
import class ClientRuntime.OrchestratorTelemetry
import class ClientRuntime.SdkHttpClient
import class Smithy.ContextBuilder
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse
@_spi(SmithyReadWrite) import class SmithyJSON.Writer
import enum AWSClientRuntime.AWSRetryErrorInfoProvider
import enum AWSClientRuntime.AWSRetryMode
import enum ClientRuntime.ClientLogMode
import enum ClientRuntime.DefaultTelemetry
import enum ClientRuntime.OrchestratorMetricsAttributesKeys
import protocol AWSClientRuntime.AWSDefaultClientConfiguration
import protocol AWSClientRuntime.AWSRegionClientConfiguration
import protocol ClientRuntime.Client
import protocol ClientRuntime.DefaultClientConfiguration
import protocol ClientRuntime.DefaultHttpClientConfiguration
import protocol ClientRuntime.HttpInterceptorProvider
import protocol ClientRuntime.IdempotencyTokenGenerator
import protocol ClientRuntime.InterceptorProvider
import protocol ClientRuntime.TelemetryProvider
import protocol Smithy.LogAgent
import protocol SmithyHTTPAPI.HTTPClient
import protocol SmithyHTTPAuthAPI.AuthSchemeResolver
import protocol SmithyIdentity.AWSCredentialIdentityResolver
import protocol SmithyIdentity.BearerTokenIdentityResolver
@_spi(SmithyReadWrite) import protocol SmithyReadWrite.SmithyWriter
import struct AWSClientRuntime.AmzSdkInvocationIdMiddleware
import struct AWSClientRuntime.EndpointResolverMiddleware
import struct AWSClientRuntime.UserAgentMiddleware
import struct AWSSDKHTTPAuth.SigV4AuthScheme
import struct ClientRuntime.AuthSchemeMiddleware
@_spi(SmithyReadWrite) import struct ClientRuntime.BodyMiddleware
import struct ClientRuntime.ContentLengthMiddleware
import struct ClientRuntime.ContentTypeMiddleware
@_spi(SmithyReadWrite) import struct ClientRuntime.DeserializeMiddleware
import struct ClientRuntime.LoggerMiddleware
import struct ClientRuntime.SignerMiddleware
import struct ClientRuntime.URLHostMiddleware
import struct ClientRuntime.URLPathMiddleware
import struct Smithy.Attributes
import struct SmithyIdentity.BearerTokenIdentity
import struct SmithyIdentity.StaticBearerTokenIdentityResolver
import struct SmithyRetries.DefaultRetryStrategy
import struct SmithyRetriesAPI.RetryStrategyOptions
import typealias SmithyHTTPAuthAPI.AuthSchemes

public class PersonalizeRuntimeClient: ClientRuntime.Client {
    public static let clientName = "PersonalizeRuntimeClient"
    let client: ClientRuntime.SdkHttpClient
    let config: PersonalizeRuntimeClient.PersonalizeRuntimeClientConfiguration
    let serviceName = "Personalize Runtime"

    public required init(config: PersonalizeRuntimeClient.PersonalizeRuntimeClientConfiguration) {
        client = ClientRuntime.SdkHttpClient(engine: config.httpClientEngine, config: config.httpClientConfiguration)
        self.config = config
    }

    public convenience init(region: Swift.String) throws {
        let config = try PersonalizeRuntimeClient.PersonalizeRuntimeClientConfiguration(region: region)
        self.init(config: config)
    }

    public convenience required init() async throws {
        let config = try await PersonalizeRuntimeClient.PersonalizeRuntimeClientConfiguration()
        self.init(config: config)
    }
}

extension PersonalizeRuntimeClient {
    public class PersonalizeRuntimeClientConfiguration: AWSClientRuntime.AWSDefaultClientConfiguration & AWSClientRuntime.AWSRegionClientConfiguration & ClientRuntime.DefaultClientConfiguration & ClientRuntime.DefaultHttpClientConfiguration {
        public var useFIPS: Swift.Bool?

        public var useDualStack: Swift.Bool?

        public var appID: Swift.String?

        public var awsCredentialIdentityResolver: any SmithyIdentity.AWSCredentialIdentityResolver

        public var awsRetryMode: AWSClientRuntime.AWSRetryMode

        public var maxAttempts: Swift.Int?

        public var region: Swift.String?

        public var signingRegion: Swift.String?

        public var endpointResolver: EndpointResolver

        public var telemetryProvider: ClientRuntime.TelemetryProvider

        public var retryStrategyOptions: SmithyRetriesAPI.RetryStrategyOptions

        public var clientLogMode: ClientRuntime.ClientLogMode

        public var endpoint: Swift.String?

        public var idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator

        public var httpClientEngine: SmithyHTTPAPI.HTTPClient

        public var httpClientConfiguration: ClientRuntime.HttpClientConfiguration

        public var authSchemes: SmithyHTTPAuthAPI.AuthSchemes?

        public var authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver

        public var bearerTokenIdentityResolver: any SmithyIdentity.BearerTokenIdentityResolver

        public private(set) var interceptorProviders: [ClientRuntime.InterceptorProvider]

        public private(set) var httpInterceptorProviders: [ClientRuntime.HttpInterceptorProvider]

        internal let logger: Smithy.LogAgent

        private init(_ useFIPS: Swift.Bool?, _ useDualStack: Swift.Bool?, _ appID: Swift.String?, _ awsCredentialIdentityResolver: any SmithyIdentity.AWSCredentialIdentityResolver, _ awsRetryMode: AWSClientRuntime.AWSRetryMode, _ maxAttempts: Swift.Int?, _ region: Swift.String?, _ signingRegion: Swift.String?, _ endpointResolver: EndpointResolver, _ telemetryProvider: ClientRuntime.TelemetryProvider, _ retryStrategyOptions: SmithyRetriesAPI.RetryStrategyOptions, _ clientLogMode: ClientRuntime.ClientLogMode, _ endpoint: Swift.String?, _ idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator, _ httpClientEngine: SmithyHTTPAPI.HTTPClient, _ httpClientConfiguration: ClientRuntime.HttpClientConfiguration, _ authSchemes: SmithyHTTPAuthAPI.AuthSchemes?, _ authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver, _ bearerTokenIdentityResolver: any SmithyIdentity.BearerTokenIdentityResolver, _ interceptorProviders: [ClientRuntime.InterceptorProvider], _ httpInterceptorProviders: [ClientRuntime.HttpInterceptorProvider]) {
            self.useFIPS = useFIPS
            self.useDualStack = useDualStack
            self.appID = appID
            self.awsCredentialIdentityResolver = awsCredentialIdentityResolver
            self.awsRetryMode = awsRetryMode
            self.maxAttempts = maxAttempts
            self.region = region
            self.signingRegion = signingRegion
            self.endpointResolver = endpointResolver
            self.telemetryProvider = telemetryProvider
            self.retryStrategyOptions = retryStrategyOptions
            self.clientLogMode = clientLogMode
            self.endpoint = endpoint
            self.idempotencyTokenGenerator = idempotencyTokenGenerator
            self.httpClientEngine = httpClientEngine
            self.httpClientConfiguration = httpClientConfiguration
            self.authSchemes = authSchemes
            self.authSchemeResolver = authSchemeResolver
            self.bearerTokenIdentityResolver = bearerTokenIdentityResolver
            self.interceptorProviders = interceptorProviders
            self.httpInterceptorProviders = httpInterceptorProviders
            self.logger = telemetryProvider.loggerProvider.getLogger(name: PersonalizeRuntimeClient.clientName)
        }

        public convenience init(useFIPS: Swift.Bool? = nil, useDualStack: Swift.Bool? = nil, appID: Swift.String? = nil, awsCredentialIdentityResolver: (any SmithyIdentity.AWSCredentialIdentityResolver)? = nil, awsRetryMode: AWSClientRuntime.AWSRetryMode? = nil, maxAttempts: Swift.Int? = nil, region: Swift.String? = nil, signingRegion: Swift.String? = nil, endpointResolver: EndpointResolver? = nil, telemetryProvider: ClientRuntime.TelemetryProvider? = nil, retryStrategyOptions: SmithyRetriesAPI.RetryStrategyOptions? = nil, clientLogMode: ClientRuntime.ClientLogMode? = nil, endpoint: Swift.String? = nil, idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator? = nil, httpClientEngine: SmithyHTTPAPI.HTTPClient? = nil, httpClientConfiguration: ClientRuntime.HttpClientConfiguration? = nil, authSchemes: SmithyHTTPAuthAPI.AuthSchemes? = nil, authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver? = nil, bearerTokenIdentityResolver: (any SmithyIdentity.BearerTokenIdentityResolver)? = nil, interceptorProviders: [ClientRuntime.InterceptorProvider]? = nil, httpInterceptorProviders: [ClientRuntime.HttpInterceptorProvider]? = nil) throws {
            self.init(useFIPS, useDualStack, try appID ?? AWSClientRuntime.AWSClientConfigDefaultsProvider.appID(), try awsCredentialIdentityResolver ?? AWSClientRuntime.AWSClientConfigDefaultsProvider.awsCredentialIdentityResolver(awsCredentialIdentityResolver), try awsRetryMode ?? AWSClientRuntime.AWSClientConfigDefaultsProvider.retryMode(), maxAttempts, region, signingRegion, try endpointResolver ?? DefaultEndpointResolver(), telemetryProvider ?? ClientRuntime.DefaultTelemetry.provider, try retryStrategyOptions ?? AWSClientConfigDefaultsProvider.retryStrategyOptions(awsRetryMode, maxAttempts), clientLogMode ?? AWSClientConfigDefaultsProvider.clientLogMode(), endpoint, idempotencyTokenGenerator ?? AWSClientConfigDefaultsProvider.idempotencyTokenGenerator(), httpClientEngine ?? AWSClientConfigDefaultsProvider.httpClientEngine(), httpClientConfiguration ?? AWSClientConfigDefaultsProvider.httpClientConfiguration(), authSchemes ?? [AWSSDKHTTPAuth.SigV4AuthScheme()], authSchemeResolver ?? DefaultPersonalizeRuntimeAuthSchemeResolver(), bearerTokenIdentityResolver ?? SmithyIdentity.StaticBearerTokenIdentityResolver(token: SmithyIdentity.BearerTokenIdentity(token: "")), interceptorProviders ?? [], httpInterceptorProviders ?? [])
        }

        public convenience init(useFIPS: Swift.Bool? = nil, useDualStack: Swift.Bool? = nil, appID: Swift.String? = nil, awsCredentialIdentityResolver: (any SmithyIdentity.AWSCredentialIdentityResolver)? = nil, awsRetryMode: AWSClientRuntime.AWSRetryMode? = nil, maxAttempts: Swift.Int? = nil, region: Swift.String? = nil, signingRegion: Swift.String? = nil, endpointResolver: EndpointResolver? = nil, telemetryProvider: ClientRuntime.TelemetryProvider? = nil, retryStrategyOptions: SmithyRetriesAPI.RetryStrategyOptions? = nil, clientLogMode: ClientRuntime.ClientLogMode? = nil, endpoint: Swift.String? = nil, idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator? = nil, httpClientEngine: SmithyHTTPAPI.HTTPClient? = nil, httpClientConfiguration: ClientRuntime.HttpClientConfiguration? = nil, authSchemes: SmithyHTTPAuthAPI.AuthSchemes? = nil, authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver? = nil, bearerTokenIdentityResolver: (any SmithyIdentity.BearerTokenIdentityResolver)? = nil, interceptorProviders: [ClientRuntime.InterceptorProvider]? = nil, httpInterceptorProviders: [ClientRuntime.HttpInterceptorProvider]? = nil) async throws {
            self.init(useFIPS, useDualStack, try appID ?? AWSClientRuntime.AWSClientConfigDefaultsProvider.appID(), try awsCredentialIdentityResolver ?? AWSClientRuntime.AWSClientConfigDefaultsProvider.awsCredentialIdentityResolver(awsCredentialIdentityResolver), try awsRetryMode ?? AWSClientRuntime.AWSClientConfigDefaultsProvider.retryMode(), maxAttempts, try await AWSClientRuntime.AWSClientConfigDefaultsProvider.region(region), try await AWSClientRuntime.AWSClientConfigDefaultsProvider.region(region), try endpointResolver ?? DefaultEndpointResolver(), telemetryProvider ?? ClientRuntime.DefaultTelemetry.provider, try retryStrategyOptions ?? AWSClientConfigDefaultsProvider.retryStrategyOptions(awsRetryMode, maxAttempts), clientLogMode ?? AWSClientConfigDefaultsProvider.clientLogMode(), endpoint, idempotencyTokenGenerator ?? AWSClientConfigDefaultsProvider.idempotencyTokenGenerator(), httpClientEngine ?? AWSClientConfigDefaultsProvider.httpClientEngine(), httpClientConfiguration ?? AWSClientConfigDefaultsProvider.httpClientConfiguration(), authSchemes ?? [AWSSDKHTTPAuth.SigV4AuthScheme()], authSchemeResolver ?? DefaultPersonalizeRuntimeAuthSchemeResolver(), bearerTokenIdentityResolver ?? SmithyIdentity.StaticBearerTokenIdentityResolver(token: SmithyIdentity.BearerTokenIdentity(token: "")), interceptorProviders ?? [], httpInterceptorProviders ?? [])
        }

        public convenience required init() async throws {
            try await self.init(useFIPS: nil, useDualStack: nil, appID: nil, awsCredentialIdentityResolver: nil, awsRetryMode: nil, maxAttempts: nil, region: nil, signingRegion: nil, endpointResolver: nil, telemetryProvider: nil, retryStrategyOptions: nil, clientLogMode: nil, endpoint: nil, idempotencyTokenGenerator: nil, httpClientEngine: nil, httpClientConfiguration: nil, authSchemes: nil, authSchemeResolver: nil, bearerTokenIdentityResolver: nil, interceptorProviders: nil, httpInterceptorProviders: nil)
        }

        public convenience init(region: String) throws {
            self.init(nil, nil, try AWSClientRuntime.AWSClientConfigDefaultsProvider.appID(), try AWSClientConfigDefaultsProvider.awsCredentialIdentityResolver(), try AWSClientRuntime.AWSClientConfigDefaultsProvider.retryMode(), nil, region, region, try DefaultEndpointResolver(), ClientRuntime.DefaultTelemetry.provider, try AWSClientConfigDefaultsProvider.retryStrategyOptions(), AWSClientConfigDefaultsProvider.clientLogMode(), nil, AWSClientConfigDefaultsProvider.idempotencyTokenGenerator(), AWSClientConfigDefaultsProvider.httpClientEngine(), AWSClientConfigDefaultsProvider.httpClientConfiguration(), [AWSSDKHTTPAuth.SigV4AuthScheme()], DefaultPersonalizeRuntimeAuthSchemeResolver(), SmithyIdentity.StaticBearerTokenIdentityResolver(token: SmithyIdentity.BearerTokenIdentity(token: "")), [], [])
        }

        public var partitionID: String? {
            return "\(PersonalizeRuntimeClient.clientName) - \(region ?? "")"
        }
        public func addInterceptorProvider(_ provider: ClientRuntime.InterceptorProvider) {
            self.interceptorProviders.append(provider)
        }

        public func addInterceptorProvider(_ provider: ClientRuntime.HttpInterceptorProvider) {
            self.httpInterceptorProviders.append(provider)
        }

    }

    public static func builder() -> ClientRuntime.ClientBuilder<PersonalizeRuntimeClient> {
        return ClientRuntime.ClientBuilder<PersonalizeRuntimeClient>(defaultPlugins: [
            ClientRuntime.DefaultClientPlugin(),
            AWSClientRuntime.DefaultAWSClientPlugin(clientName: self.clientName),
            DefaultAWSAuthSchemePlugin()
        ])
    }
}

extension PersonalizeRuntimeClient {
    /// Performs the `GetActionRecommendations` operation on the `AmazonPersonalizeRuntime` service.
    ///
    /// Returns a list of recommended actions in sorted in descending order by prediction score. Use the GetActionRecommendations API if you have a custom campaign that deploys a solution version trained with a PERSONALIZED_ACTIONS recipe. For more information about PERSONALIZED_ACTIONS recipes, see [PERSONALIZED_ACTIONS recipes](https://docs.aws.amazon.com/personalize/latest/dg/nexts-best-action-recipes.html). For more information about getting action recommendations, see [Getting action recommendations](https://docs.aws.amazon.com/personalize/latest/dg/get-action-recommendations.html).
    ///
    /// - Parameter GetActionRecommendationsInput : [no documentation found]
    ///
    /// - Returns: `GetActionRecommendationsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidInputException` : Provide a valid value for the field or parameter.
    /// - `ResourceNotFoundException` : The specified resource does not exist.
    public func getActionRecommendations(input: GetActionRecommendationsInput) async throws -> GetActionRecommendationsOutput {
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "getActionRecommendations")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withPartitionID(value: config.partitionID)
                      .withAuthSchemes(value: config.authSchemes ?? [])
                      .withAuthSchemeResolver(value: config.authSchemeResolver)
                      .withUnsignedPayloadTrait(value: false)
                      .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
                      .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4a")
                      .withRegion(value: config.region)
                      .withSigningName(value: "personalize")
                      .withSigningRegion(value: config.signingRegion)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<GetActionRecommendationsInput, GetActionRecommendationsOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput>(GetActionRecommendationsInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput>())
        builder.interceptors.add(ClientRuntime.ContentTypeMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput>(contentType: "application/json"))
        builder.serialize(ClientRuntime.BodyMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: GetActionRecommendationsInput.write(value:to:)))
        builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<GetActionRecommendationsOutput>(GetActionRecommendationsOutput.httpOutput(from:), GetActionRecommendationsOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<GetActionRecommendationsOutput>())
        let endpointParams = EndpointParams(endpoint: config.endpoint, region: config.region, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false)
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<GetActionRecommendationsOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: $0) }, endpointParams: endpointParams))
        builder.interceptors.add(AWSClientRuntime.UserAgentMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput>(serviceID: serviceName, version: "1.0", config: config))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<GetActionRecommendationsOutput>())
        builder.interceptors.add(AWSClientRuntime.AmzSdkInvocationIdMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput>())
        builder.interceptors.add(AWSClientRuntime.AmzSdkRequestMiddleware<GetActionRecommendationsInput, GetActionRecommendationsOutput>(maxRetries: config.retryStrategyOptions.maxRetriesBase))
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "PersonalizeRuntime")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "GetActionRecommendations")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.execute(input: input)
    }

    /// Performs the `GetPersonalizedRanking` operation on the `AmazonPersonalizeRuntime` service.
    ///
    /// Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user. The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.
    ///
    /// - Parameter GetPersonalizedRankingInput : [no documentation found]
    ///
    /// - Returns: `GetPersonalizedRankingOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidInputException` : Provide a valid value for the field or parameter.
    /// - `ResourceNotFoundException` : The specified resource does not exist.
    public func getPersonalizedRanking(input: GetPersonalizedRankingInput) async throws -> GetPersonalizedRankingOutput {
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "getPersonalizedRanking")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withPartitionID(value: config.partitionID)
                      .withAuthSchemes(value: config.authSchemes ?? [])
                      .withAuthSchemeResolver(value: config.authSchemeResolver)
                      .withUnsignedPayloadTrait(value: false)
                      .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
                      .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4a")
                      .withRegion(value: config.region)
                      .withSigningName(value: "personalize")
                      .withSigningRegion(value: config.signingRegion)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<GetPersonalizedRankingInput, GetPersonalizedRankingOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput>(GetPersonalizedRankingInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput>())
        builder.interceptors.add(ClientRuntime.ContentTypeMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput>(contentType: "application/json"))
        builder.serialize(ClientRuntime.BodyMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: GetPersonalizedRankingInput.write(value:to:)))
        builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<GetPersonalizedRankingOutput>(GetPersonalizedRankingOutput.httpOutput(from:), GetPersonalizedRankingOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<GetPersonalizedRankingOutput>())
        let endpointParams = EndpointParams(endpoint: config.endpoint, region: config.region, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false)
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<GetPersonalizedRankingOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: $0) }, endpointParams: endpointParams))
        builder.interceptors.add(AWSClientRuntime.UserAgentMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput>(serviceID: serviceName, version: "1.0", config: config))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<GetPersonalizedRankingOutput>())
        builder.interceptors.add(AWSClientRuntime.AmzSdkInvocationIdMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput>())
        builder.interceptors.add(AWSClientRuntime.AmzSdkRequestMiddleware<GetPersonalizedRankingInput, GetPersonalizedRankingOutput>(maxRetries: config.retryStrategyOptions.maxRetriesBase))
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "PersonalizeRuntime")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "GetPersonalizedRanking")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.execute(input: input)
    }

    /// Performs the `GetRecommendations` operation on the `AmazonPersonalizeRuntime` service.
    ///
    /// Returns a list of recommended items. For campaigns, the campaign's Amazon Resource Name (ARN) is required and the required user and item input depends on the recipe type used to create the solution backing the campaign as follows:
    ///
    /// * USER_PERSONALIZATION - userId required, itemId not used
    ///
    /// * RELATED_ITEMS - itemId required, userId not used
    ///
    ///
    /// Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API. For recommenders, the recommender's ARN is required and the required item and user input depends on the use case (domain-based recipe) backing the recommender. For information on use case requirements see [Choosing recommender use cases](https://docs.aws.amazon.com/personalize/latest/dg/domain-use-cases.html).
    ///
    /// - Parameter GetRecommendationsInput : [no documentation found]
    ///
    /// - Returns: `GetRecommendationsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidInputException` : Provide a valid value for the field or parameter.
    /// - `ResourceNotFoundException` : The specified resource does not exist.
    public func getRecommendations(input: GetRecommendationsInput) async throws -> GetRecommendationsOutput {
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "getRecommendations")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withPartitionID(value: config.partitionID)
                      .withAuthSchemes(value: config.authSchemes ?? [])
                      .withAuthSchemeResolver(value: config.authSchemeResolver)
                      .withUnsignedPayloadTrait(value: false)
                      .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
                      .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
                      .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4a")
                      .withRegion(value: config.region)
                      .withSigningName(value: "personalize")
                      .withSigningRegion(value: config.signingRegion)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<GetRecommendationsInput, GetRecommendationsOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<GetRecommendationsInput, GetRecommendationsOutput>(GetRecommendationsInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<GetRecommendationsInput, GetRecommendationsOutput>())
        builder.interceptors.add(ClientRuntime.ContentTypeMiddleware<GetRecommendationsInput, GetRecommendationsOutput>(contentType: "application/json"))
        builder.serialize(ClientRuntime.BodyMiddleware<GetRecommendationsInput, GetRecommendationsOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: GetRecommendationsInput.write(value:to:)))
        builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<GetRecommendationsInput, GetRecommendationsOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<GetRecommendationsOutput>(GetRecommendationsOutput.httpOutput(from:), GetRecommendationsOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<GetRecommendationsInput, GetRecommendationsOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<GetRecommendationsOutput>())
        let endpointParams = EndpointParams(endpoint: config.endpoint, region: config.region, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false)
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<GetRecommendationsOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: $0) }, endpointParams: endpointParams))
        builder.interceptors.add(AWSClientRuntime.UserAgentMiddleware<GetRecommendationsInput, GetRecommendationsOutput>(serviceID: serviceName, version: "1.0", config: config))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<GetRecommendationsOutput>())
        builder.interceptors.add(AWSClientRuntime.AmzSdkInvocationIdMiddleware<GetRecommendationsInput, GetRecommendationsOutput>())
        builder.interceptors.add(AWSClientRuntime.AmzSdkRequestMiddleware<GetRecommendationsInput, GetRecommendationsOutput>(maxRetries: config.retryStrategyOptions.maxRetriesBase))
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "PersonalizeRuntime")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "GetRecommendations")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.execute(input: input)
    }

}