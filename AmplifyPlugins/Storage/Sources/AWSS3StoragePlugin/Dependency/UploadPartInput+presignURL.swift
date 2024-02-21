//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSS3
import ClientRuntime
import AWSClientRuntime

extension UploadPartInput {
    func customPresignURL(config: S3Client.S3ClientConfiguration, expiration: TimeInterval) async throws -> ClientRuntime.URL? {
        let serviceName = "S3"
        let input = self
        let context = ClientRuntime.HttpContextBuilder()
            .withMethod(value: .put)
            .withServiceName(value: serviceName)
            .withOperation(value: "uploadPart")
            .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
            .withLogger(value: config.logger)
            .withPartitionID(value: config.partitionID)
            .withCredentialsProvider(value: config.credentialsProvider)
            .withRegion(value: config.region)
            .withSigningName(value: "s3")
            .withSigningRegion(value: config.signingRegion)
            .build()
        var operation = ClientRuntime.OperationStack<UploadPartInput, UploadPartOutput>(id: "uploadPart")
        operation.initializeStep.intercept(
            position: .after, middleware: ClientRuntime.URLPathMiddleware<UploadPartInput, UploadPartOutput>(UploadPartInput.urlPathProvider(_:)))
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<UploadPartInput, UploadPartOutput>())
        operation.buildStep.intercept(
            position: .before,
            middleware: EndpointResolverMiddleware<UploadPartOutput>(
                endpointResolver: config.serviceSpecific.endpointResolver,
                endpointParams: config.endpointParams(withBucket: input.bucket)
            )
        )
        operation.serializeStep.intercept(
            position: .after, middleware: ClientRuntime.QueryItemMiddleware<UploadPartInput, UploadPartOutput>(UploadPartInput.queryItemProvider(_:)))
        operation.finalizeStep.intercept(
            position: .after, 
            middleware: ClientRuntime.RetryMiddleware<ClientRuntime.DefaultRetryStrategy, AWSClientRuntime.AWSRetryErrorInfoProvider, UploadPartOutput>(
                options: config.retryStrategyOptions))
        let sigv4Config = AWSClientRuntime.SigV4Config(
            signatureType: .requestQueryParams,
            useDoubleURIEncode: false,
            expiration: expiration,
            unsignedBody: true,
            signingAlgorithm: .sigv4)
        operation.finalizeStep.intercept(
            position: .before, middleware: AWSClientRuntime.SigV4Middleware<UploadPartOutput>(config: sigv4Config))
        operation.deserializeStep.intercept(
            position: .after, middleware: ClientRuntime.LoggerMiddleware<UploadPartOutput>(clientLogMode: config.clientLogMode))
        operation.deserializeStep.intercept(
            position: .after, middleware: AWSClientRuntime.AWSS3ErrorWith200StatusXMLMiddleware<UploadPartOutput>())
        let presignedRequestBuilder = try await operation.presignedRequest(
            context: context, input: input, output: UploadPartOutput(), next: ClientRuntime.NoopHandler())
         guard let builtRequest = presignedRequestBuilder?.build(), let presignedURL = builtRequest.endpoint.url else {
             return nil
         }
         return presignedURL
     }

    static func urlPathProvider(_ value: UploadPartInput) -> Swift.String? {
        guard let key = value.key else {
            return nil
        }
        return "/\(key.urlPercentEncoding(encodeForwardSlash: false))"
    }

 }

extension UploadPartInput {

    static func queryItemProvider(_ value: UploadPartInput) throws -> [ClientRuntime.SDKURLQueryItem] {
        var items = [ClientRuntime.SDKURLQueryItem]()
        items.append(ClientRuntime.SDKURLQueryItem(name: "x-id", value: "UploadPart"))
        guard let partNumber = value.partNumber else {
            let message = "Creating a URL Query Item failed. partNumber is required and must not be nil."
            throw ClientRuntime.ClientError.unknownError(message)
        }
        let partNumberQueryItem = ClientRuntime.SDKURLQueryItem(name: "partNumber".urlPercentEncoding(), value: Swift.String(partNumber).urlPercentEncoding())
        items.append(partNumberQueryItem)
        guard let uploadId = value.uploadId else {
            let message = "Creating a URL Query Item failed. uploadId is required and must not be nil."
            throw ClientRuntime.ClientError.unknownError(message)
        }
        let uploadIdQueryItem = ClientRuntime.SDKURLQueryItem(name: "uploadId".urlPercentEncoding(), value: Swift.String(uploadId).urlPercentEncoding())
        items.append(uploadIdQueryItem)
        return items
    }
}
