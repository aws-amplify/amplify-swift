// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation

import AWSS3
import ClientRuntime
import AWSClientRuntime

//extension PutObjectInput {
//
//    public func customPresignURL(config: S3ClientConfigurationProtocol, expiration: Swift.Int64) async throws -> ClientRuntime.URL? {
//        let serviceName = "S3"
//        let input = self
//        let encoder = ClientRuntime.XMLEncoder()
//        encoder.dateEncodingStrategy = .secondsSince1970
//        let decoder = ClientRuntime.XMLDecoder()
//        decoder.dateDecodingStrategy = .secondsSince1970
//        decoder.trimValueWhitespaces = false
//        decoder.removeWhitespaceElements = true
//        let context = ClientRuntime.HttpContextBuilder()
//            .withEncoder(value: encoder)
//            .withDecoder(value: decoder)
//            .withMethod(value: .put)
//            .withServiceName(value: serviceName)
//            .withOperation(value: "putObject")
//            .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
//            .withLogger(value: config.logger)
//            .withCredentialsProvider(value: config.credentialsProvider)
//            .withRegion(value: config.region)
//            .withSigningName(value: "s3")
//            .withSigningRegion(value: config.signingRegion)
//        var operation = ClientRuntime.OperationStack<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>(id: "putObject")
//        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>())
//        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<PutObjectInput, PutObjectOutputResponse>())
//        let endpointParams = EndpointParams(accelerate: config.accelerate ?? false, bucket: input.bucket, disableMultiRegionAccessPoints: config.disableMultiRegionAccessPoints ?? false, endpoint: config.endpoint, forcePathStyle: config.forcePathStyle, region: config.region, useArnRegion: config.useArnRegion, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false, useGlobalEndpoint: config.useGlobalEndpoint ?? false)
//        operation.buildStep.intercept(position: .before, middleware: EndpointResolverMiddleware<PutObjectOutputResponse, PutObjectOutputError>(endpointResolver: config.endpointResolver, endpointParams: endpointParams))
//        operation.serializeStep.intercept(position: .after, middleware: PutObjectInputBodyMiddleware())
//        operation.finalizeStep.intercept(position: .after, middleware: AWSClientRuntime.RetryerMiddleware<PutObjectOutputResponse, PutObjectOutputError>(retryer: config.retryer))
//        let sigv4Config = AWSClientRuntime.SigV4Config(
//            signatureType: .requestQueryParams,
//            useDoubleURIEncode: false,
//            expiration: expiration,
//            unsignedBody: true)
//        operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware<PutObjectOutputResponse, PutObjectOutputError>(config: sigv4Config))
//        operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware<PutObjectOutputResponse, PutObjectOutputError>(clientLogMode: config.clientLogMode))
//        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<PutObjectOutputResponse, PutObjectOutputError>())
//        let presignedRequestBuilder = try await operation.presignedRequest(context: context.build(), input: input, next: ClientRuntime.NoopHandler())
//        guard let builtRequest = presignedRequestBuilder?.build(), let presignedURL = builtRequest.endpoint.url else {
//            return nil
//        }
//        return presignedURL
//    }
//}
