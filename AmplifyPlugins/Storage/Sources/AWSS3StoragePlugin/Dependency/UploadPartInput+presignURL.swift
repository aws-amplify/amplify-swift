//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSS3
@_spi(SmithyReadWrite) import ClientRuntime
@_spi(UnknownAWSHTTPServiceError) @_spi(SmithyReadWrite) @_spi(AWSEndpointResolverMiddleware) import AWSClientRuntime
import Smithy
import SmithyHTTPAPI
import SmithyRetries
@_spi(SmithyReadWrite) import SmithyXML

// swiftlint:disable identifier_name
// swiftlint:disable line_length
extension UploadPartInput {
    func customPresignURL(
        config: S3Client.S3ClientConfiguration,
        expiration: Foundation.TimeInterval
    ) async throws -> Foundation.URL? {
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
            .withLogger(value: config.telemetryProvider.loggerProvider.getLogger(name: S3Client.clientName))
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
            .withUnsignedPayloadTrait(value: true)
            .build()
        let builder = ClientRuntime.OrchestratorBuilder<UploadPartInput, UploadPartOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<UploadPartInput, UploadPartOutput>(UploadPartInput.customUrlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<UploadPartInput, UploadPartOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<UploadPartOutput>(UploadPartOutput.customHttpOutput(from:), CustomUploadPartOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<UploadPartInput, UploadPartOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<UploadPartOutput>())
        let endpointParamsBlock = { [config] (context: Smithy.Context) in
            EndpointParams(accelerate: config.accelerate ?? false, bucket: input.bucket, disableMultiRegionAccessPoints: config.disableMultiRegionAccessPoints ?? false, disableS3ExpressSessionAuth: config.disableS3ExpressSessionAuth, endpoint: config.endpoint, forcePathStyle: config.forcePathStyle ?? false, key: input.key, region: config.region, useArnRegion: config.useArnRegion, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false, useGlobalEndpoint: config.useGlobalEndpoint ?? false)
        }
        context.set(key: Smithy.AttributeKey<EndpointParams>(name: "EndpointParams"), value: endpointParamsBlock(context))
        builder.applyEndpoint(AWSClientRuntime.AWSEndpointResolverMiddleware<UploadPartOutput, EndpointParams>(paramsBlock: endpointParamsBlock, resolverBlock: { [config] in try config.endpointResolver.resolve(params: $0) }))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<UploadPartOutput>())
        builder.interceptors.add(AWSClientRuntime.AWSS3ErrorWith200StatusXMLMiddleware<UploadPartInput, UploadPartOutput>())
        builder.interceptors.add(AWSClientRuntime.FlexibleChecksumsRequestMiddleware<UploadPartInput, UploadPartOutput>(requestChecksumRequired: false, checksumAlgorithm: input.checksumAlgorithm?.rawValue, checksumAlgoHeaderName: "x-amz-sdk-checksum-algorithm"))
        builder.serialize(UploadPartPresignedMiddleware())
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
}

private extension UploadPartInput {
    static func customUrlPathProvider(_ value: UploadPartInput) -> Swift.String? {
        guard let key = value.key else {
            return nil
        }
        return "/\(key.urlPercentEncoding(encodeForwardSlash: false))"
    }
}

private extension UploadPartOutput {
    static func customHttpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> UploadPartOutput {
        var value = UploadPartOutput()
        if let bucketKeyEnabledHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-bucket-key-enabled") {
            value.bucketKeyEnabled = Swift.Bool(bucketKeyEnabledHeaderValue) ?? false
        }
        if let checksumCRC32HeaderValue = httpResponse.headers.value(for: "x-amz-checksum-crc32") {
            value.checksumCRC32 = checksumCRC32HeaderValue
        }
        if let checksumCRC32CHeaderValue = httpResponse.headers.value(for: "x-amz-checksum-crc32c") {
            value.checksumCRC32C = checksumCRC32CHeaderValue
        }
        if let checksumSHA1HeaderValue = httpResponse.headers.value(for: "x-amz-checksum-sha1") {
            value.checksumSHA1 = checksumSHA1HeaderValue
        }
        if let checksumSHA256HeaderValue = httpResponse.headers.value(for: "x-amz-checksum-sha256") {
            value.checksumSHA256 = checksumSHA256HeaderValue
        }
        if let eTagHeaderValue = httpResponse.headers.value(for: "ETag") {
            value.eTag = eTagHeaderValue
        }
        if let requestChargedHeaderValue = httpResponse.headers.value(for: "x-amz-request-charged") {
            value.requestCharged = S3ClientTypes.RequestCharged(rawValue: requestChargedHeaderValue)
        }
        if let sseCustomerAlgorithmHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-customer-algorithm") {
            value.sseCustomerAlgorithm = sseCustomerAlgorithmHeaderValue
        }
        if let sseCustomerKeyMD5HeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-customer-key-MD5") {
            value.sseCustomerKeyMD5 = sseCustomerKeyMD5HeaderValue
        }
        if let ssekmsKeyIdHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-aws-kms-key-id") {
            value.ssekmsKeyId = ssekmsKeyIdHeaderValue
        }
        if let serverSideEncryptionHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption") {
            value.serverSideEncryption = S3ClientTypes.ServerSideEncryption(rawValue: serverSideEncryptionHeaderValue)
        }
        return value
    }
}

private enum CustomUploadPartOutputError {
    static func httpError(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> Swift.Error {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let baseError = try AWSClientRuntime.RestXMLError(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: true)
        if let error = baseError.customError() { return error }
        if baseError.httpResponse.statusCode == .notFound && baseError.httpResponse.body.isEmpty {
            return CustomUploadPartOutputError.NotFound(
                httpResponse: baseError.httpResponse,
                message: baseError.requestID,
                requestID: baseError.message,
                requestID2: baseError.requestID2
            )
        }
        switch baseError.code {
            default: return try AWSClientRuntime.UnknownAWSHTTPServiceError.makeError(baseError: baseError)
        }
    }

    private struct NotFound: ClientRuntime.ModeledError, AWSClientRuntime.AWSS3ServiceError, ClientRuntime.HTTPError, Swift.Error {
        static var typeName: Swift.String { "NotFound" }
        static var fault: ClientRuntime.ErrorFault { .client }
        static var isRetryable: Swift.Bool { false }
        static var isThrottling: Swift.Bool { false }
        var httpResponse = SmithyHTTPAPI.HTTPResponse()
        var message: Swift.String?
        var requestID: Swift.String?
        var requestID2: Swift.String?
    }
}

private struct UploadPartPresignedMiddleware: Smithy.RequestMessageSerializer {
    typealias InputType = UploadPartInput
    typealias RequestType = SmithyHTTPAPI.HTTPRequest

    let id: Swift.String = "UploadPartPresignedMiddleware"

    func apply(
        input: InputType,
        builder: SmithyHTTPAPI.HTTPRequestBuilder,
        attributes: Smithy.Context
    ) throws {
        builder.withQueryItem(.init(
            name: "x-id",
            value: "UploadPart")
        )

        guard let partNumber = input.partNumber else {
            throw ClientError.invalidValue("partNumber is required and must not be nil.")
        }
        builder.withQueryItem(.init(
            name: "partNumber".urlPercentEncoding(),
            value: Swift.String(partNumber).urlPercentEncoding())
        )

        guard let uploadId = input.uploadId else {
            throw ClientError.invalidValue("uploadId is required and must not be nil.")
        }
        builder.withQueryItem(.init(
            name: "uploadId".urlPercentEncoding(),
            value: Swift.String(uploadId).urlPercentEncoding())
        )
    }
}
