// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation

import AWSS3
import ClientRuntime
import AWSClientRuntime

extension GetObjectInput {
    public func customPresignURL(config: S3ClientConfigurationProtocol, expiration: Swift.Int64) async throws -> ClientRuntime.URL? {
        let serviceName = "S3"
        let input = self
        let encoder = ClientRuntime.XMLEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = ClientRuntime.XMLDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.trimValueWhitespaces = false
        decoder.removeWhitespaceElements = true
        let context = ClientRuntime.HttpContextBuilder()
            .withEncoder(value: encoder)
            .withDecoder(value: decoder)
            .withMethod(value: .get)
            .withServiceName(value: serviceName)
            .withOperation(value: "getObject")
            .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
            .withLogger(value: config.logger)
            .withCredentialsProvider(value: config.credentialsProvider)
            .withRegion(value: config.region)
            .withSigningName(value: "s3")
            .withSigningRegion(value: config.signingRegion)
        var operation = ClientRuntime.OperationStack<GetObjectInput, GetObjectOutputResponse, GetObjectOutputError>(id: "getObject")
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<GetObjectInput, GetObjectOutputResponse, GetObjectOutputError>())
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<GetObjectInput, GetObjectOutputResponse>())
        let endpointParams = EndpointParams(accelerate: config.accelerate ?? false, bucket: input.bucket, disableMultiRegionAccessPoints: config.disableMultiRegionAccessPoints ?? false, endpoint: config.endpoint, forcePathStyle: config.forcePathStyle, region: config.region, useArnRegion: config.useArnRegion, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false, useGlobalEndpoint: config.useGlobalEndpoint ?? false)
        operation.buildStep.intercept(position: .before, middleware: EndpointResolverMiddleware<GetObjectOutputResponse, GetObjectOutputError>(endpointResolver: config.endpointResolver, endpointParams: endpointParams))
        operation.serializeStep.intercept(position: .after, middleware: GetObjectInputGETQueryItemMiddleware())
        operation.finalizeStep.intercept(position: .after, middleware: AWSClientRuntime.RetryerMiddleware<GetObjectOutputResponse, GetObjectOutputError>(retryer: config.retryer))
        let sigv4Config = AWSClientRuntime.SigV4Config(
            signatureType: .requestQueryParams,
            useDoubleURIEncode: false,
            expiration: expiration,
            unsignedBody: true)
        operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware<GetObjectOutputResponse, GetObjectOutputError>(config: sigv4Config))
        operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware<GetObjectOutputResponse, GetObjectOutputError>(clientLogMode: config.clientLogMode))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<GetObjectOutputResponse, GetObjectOutputError>())
        let presignedRequestBuilder = try await operation.presignedRequest(context: context.build(), input: input, next: ClientRuntime.NoopHandler())
        guard let builtRequest = presignedRequestBuilder?.build(), let presignedURL = builtRequest.endpoint.url else {
            return nil
        }
        return presignedURL
    }
}

