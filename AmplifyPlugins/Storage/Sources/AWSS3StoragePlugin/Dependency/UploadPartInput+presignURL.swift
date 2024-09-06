//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
@testable import AWSS3
@_spi(SmithyReadWrite) import ClientRuntime
import AWSClientRuntime
import Smithy
import SmithyHTTPAPI
import SmithyRetries

// swiftlint:disable identifier_name
// swiftlint:disable line_length
extension UploadPartInput {
    public func customPresignURL(config: S3Client.S3ClientConfiguration, expiration: Foundation.TimeInterval) async throws -> Foundation.URL? {
        let serviceName = "S3"
        let input = self
        let client: (SmithyHTTPAPI.HTTPRequest, Smithy.Context) async throws -> SmithyHTTPAPI.HTTPResponse = { (_, _) in
            throw Smithy.ClientError.unknownError("No HTTP client configured for presigned request")
        }
        let context = Smithy.ContextBuilder()
            .withMethod(value: .put)
            .withServiceName(value: serviceName)
            .withOperation(value: "uploadPart")
            .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
            .withLogger(value: config.logger)
            .withPartitionID(value: config.partitionID)
            .withAuthSchemes(value: config.authSchemes ?? [])
            .withAuthSchemeResolver(value: config.authSchemeResolver)
            .withUnsignedPayloadTrait(value: false)
            .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
            .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
            .withFlowType(value: .PRESIGN_URL)
            .withExpiration(value: expiration)
            .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
            .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4a")
            .withRegion(value: config.region)
            .withSigningName(value: "s3")
            .withSigningRegion(value: config.signingRegion)
            .build()
        let builder = ClientRuntime.OrchestratorBuilder<UploadPartInput, UploadPartOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { (provider: any ClientRuntime.HttpInterceptorProvider) -> Void in
            let i: any ClientRuntime.HttpInterceptor<UploadPartInput, UploadPartOutput> = provider.create()
            builder.interceptors.add(i)
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<UploadPartInput, UploadPartOutput>(UploadPartInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<UploadPartInput, UploadPartOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<UploadPartOutput>(UploadPartOutput.httpOutput(from:), PutObjectOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<UploadPartInput, UploadPartOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<UploadPartOutput>())
        let endpointParams = EndpointParams(accelerate: config.accelerate ?? false, bucket: input.bucket, disableMultiRegionAccessPoints: config.disableMultiRegionAccessPoints ?? false, disableS3ExpressSessionAuth: config.disableS3ExpressSessionAuth, endpoint: config.endpoint, forcePathStyle: config.forcePathStyle ?? false, key: input.key, region: config.region, useArnRegion: config.useArnRegion, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false, useGlobalEndpoint: config.useGlobalEndpoint ?? false)
        context.attributes.set(key: Smithy.AttributeKey<EndpointParams>(name: "EndpointParams"), value: endpointParams)
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<UploadPartOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: $0) }, endpointParams: endpointParams))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<UploadPartOutput>())
        builder.interceptors.add(AWSClientRuntime.AWSS3ErrorWith200StatusXMLMiddleware<UploadPartInput, UploadPartOutput>())
        builder.interceptors.add(AWSClientRuntime.FlexibleChecksumsRequestMiddleware<UploadPartInput, UploadPartOutput>(checksumAlgorithm: input.checksumAlgorithm?.rawValue))
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "S3")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "UploadPart")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.presignRequest(input: input).endpoint.url
    }

    static func urlPathProvider(_ value: UploadPartInput) -> Swift.String? {
        guard let key = value.key else {
            return nil
        }
        return "/\(key.urlPercentEncoding(encodeForwardSlash: false))"
    }

 }

extension UploadPartInput {

    static func queryItemProvider(_ value: UploadPartInput) throws -> [URIQueryItem] {
        var items = [URIQueryItem]()
        items.append(URIQueryItem(name: "x-id", value: "UploadPart"))
        guard let partNumber = value.partNumber else {
            let message = "Creating a URL Query Item failed. partNumber is required and must not be nil."
            throw ClientError.unknownError(message)
        }
        let partNumberQueryItem = URIQueryItem(name: "partNumber".urlPercentEncoding(), value: Swift.String(partNumber).urlPercentEncoding())
        items.append(partNumberQueryItem)
        guard let uploadId = value.uploadId else {
            let message = "Creating a URL Query Item failed. uploadId is required and must not be nil."
            throw ClientError.unknownError(message)
        }
        let uploadIdQueryItem = URIQueryItem(name: "uploadId".urlPercentEncoding(), value: Swift.String(uploadId).urlPercentEncoding())
        items.append(uploadIdQueryItem)
        return items
    }
}
