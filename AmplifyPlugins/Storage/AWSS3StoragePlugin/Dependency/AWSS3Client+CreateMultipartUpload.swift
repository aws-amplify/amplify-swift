//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import ClientRuntime
import AWSClientRuntime

extension S3Client {

    func createMultipartUpload(config: AWSClientRuntime.AWSClientConfiguration,
                                      input: CreateMultipartUploadInput,
                                      completion: @escaping (ClientRuntime.SdkResult<CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>) -> Void)
    {
        let serviceName = "S3"
        let client = ClientRuntime.SdkHttpClient(engine: config.httpClientEngine, config: config.httpClientConfiguration)
        let encoder = ClientRuntime.XMLEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = ClientRuntime.XMLDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.trimValueWhitespaces = false
        decoder.removeWhitespaceElements = true

        let context = ClientRuntime.HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withDecoder(value: decoder)
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "createMultipartUpload")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withCredentialsProvider(value: config.credentialsProvider)
                      .withRegion(value: config.region)
                      .withSigningName(value: "s3")
                      .withSigningRegion(value: config.signingRegion)
        var operation = ClientRuntime.OperationStack<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>(id: "createMultipartUpload")
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>())
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>())
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.EndpointResolverMiddleware(endpointResolver: config.endpointResolver, serviceId: serviceName))
        let apiMetadata = AWSClientRuntime.APIMetadata(serviceId: serviceName, version: "1.0")
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.UserAgentMiddleware(metadata: AWSClientRuntime.AWSUserAgentMetadata.fromEnv(apiMetadata: apiMetadata, frameworkMetadata: config.frameworkMetadata)))
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>())
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.QueryItemMiddleware<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>())
        operation.finalizeStep.intercept(position: .after, middleware: AWSClientRuntime.RetryerMiddleware(retryer: config.retryer))
        let sigv4Config = AWSClientRuntime.SigV4Config(useDoubleURIEncode: true, shouldNormalizeURIPath: true, signedBodyHeader: .contentSha256, unsignedBody: false)
        operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware(config: sigv4Config))
        operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware(clientLogMode: config.clientLogMode))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware())
        let result = operation.handleMiddleware(context: context.build(), input: input, next: client.getHandler())
        completion(result)
    }

}
