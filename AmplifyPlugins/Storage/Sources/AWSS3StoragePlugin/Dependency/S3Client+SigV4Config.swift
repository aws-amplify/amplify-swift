//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSS3
import ClientRuntime

extension S3Client {
    func completeMultipartUpload(input: CompleteMultipartUploadInput,
                                 config: AWSClientRuntime.AWSClientConfiguration) async throws -> CompleteMultipartUploadOutputResponse
    {
        var operation = ClientRuntime.OperationStack<CompleteMultipartUploadInput, CompleteMultipartUploadOutputResponse, CompleteMultipartUploadOutputError>(id: "completeMultipartUpload")
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<CompleteMultipartUploadInput, CompleteMultipartUploadOutputResponse, CompleteMultipartUploadOutputError>())
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<CompleteMultipartUploadInput, CompleteMultipartUploadOutputResponse>())
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.EndpointResolverMiddleware<CompleteMultipartUploadOutputResponse, CompleteMultipartUploadOutputError>(endpointResolver: config.endpointResolver, serviceId: "S3"))
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.UserAgentMiddleware(metadata: AWSClientRuntime.AWSUserAgentMetadata.fromEnv(apiMetadata: apiMetadata, frameworkMetadata: config.frameworkMetadata)))
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<CompleteMultipartUploadInput, CompleteMultipartUploadOutputResponse>())
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.QueryItemMiddleware<CompleteMultipartUploadInput, CompleteMultipartUploadOutputResponse>())
        operation.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<CompleteMultipartUploadInput, CompleteMultipartUploadOutputResponse>(contentType: "application/xml"))
        operation.serializeStep.intercept(position: .after, middleware: CompleteMultipartUploadInputBodyMiddleware())
        operation.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operation.finalizeStep.intercept(position: .after, middleware: AWSClientRuntime.RetryerMiddleware<CompleteMultipartUploadOutputResponse, CompleteMultipartUploadOutputError>(retryer: config.retryer))
        operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware<CompleteMultipartUploadOutputResponse, CompleteMultipartUploadOutputError>(config: sigv4Config))
        operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware<CompleteMultipartUploadOutputResponse, CompleteMultipartUploadOutputError>(clientLogMode: config.clientLogMode))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<CompleteMultipartUploadOutputResponse, CompleteMultipartUploadOutputError>())

        let context = createContext(config: config, method: .post, operation: "completeMultipartUpload")
        let client = createClient(config: config)
        return try await operation.handleMiddleware(context: context.build(),
                                                    input: input,
                                                    next: client.getHandler())
    }

    func createMultipartUpload(input: CreateMultipartUploadInput,
                               config: AWSClientRuntime.AWSClientConfiguration) async throws -> CreateMultipartUploadOutputResponse
    {
        var operation = ClientRuntime.OperationStack<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>(id: "createMultipartUpload")
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>())
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse>())
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.EndpointResolverMiddleware<CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>(endpointResolver: config.endpointResolver, serviceId: "S3"))
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.UserAgentMiddleware(metadata: AWSClientRuntime.AWSUserAgentMetadata.fromEnv(apiMetadata: apiMetadata, frameworkMetadata: config.frameworkMetadata)))
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse>())
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.QueryItemMiddleware<CreateMultipartUploadInput, CreateMultipartUploadOutputResponse>())
        operation.finalizeStep.intercept(position: .after, middleware: AWSClientRuntime.RetryerMiddleware<CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>(retryer: config.retryer))
        operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware<CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>(config: sigv4Config))
        operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware<CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>(clientLogMode: config.clientLogMode))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>())

        let context = createContext(config: config, method: .post, operation: "createMultipartUpload")
        let client = createClient(config: config)
        return try await operation.handleMiddleware(context: context.build(),
                                                    input: input,
                                                    next: client.getHandler())
    }

    func deleteObject(input: DeleteObjectInput,
                      config: AWSClientRuntime.AWSClientConfiguration) async throws -> DeleteObjectOutputResponse
    {
        var operation = ClientRuntime.OperationStack<DeleteObjectInput, DeleteObjectOutputResponse, DeleteObjectOutputError>(id: "deleteObject")
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<DeleteObjectInput, DeleteObjectOutputResponse, DeleteObjectOutputError>())
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<DeleteObjectInput, DeleteObjectOutputResponse>())
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.EndpointResolverMiddleware<DeleteObjectOutputResponse, DeleteObjectOutputError>(endpointResolver: config.endpointResolver, serviceId: "S3"))
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.UserAgentMiddleware(metadata: AWSClientRuntime.AWSUserAgentMetadata.fromEnv(apiMetadata: apiMetadata, frameworkMetadata: config.frameworkMetadata)))
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<DeleteObjectInput, DeleteObjectOutputResponse>())
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.QueryItemMiddleware<DeleteObjectInput, DeleteObjectOutputResponse>())
        operation.finalizeStep.intercept(position: .after, middleware: AWSClientRuntime.RetryerMiddleware<DeleteObjectOutputResponse, DeleteObjectOutputError>(retryer: config.retryer))
        operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware<DeleteObjectOutputResponse, DeleteObjectOutputError>(config: sigv4Config))
        operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware<DeleteObjectOutputResponse, DeleteObjectOutputError>(clientLogMode: config.clientLogMode))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<DeleteObjectOutputResponse, DeleteObjectOutputError>())

        let context = createContext(config: config, method: .delete, operation: "deleteObject")
        let client = createClient(config: config)
        return try await operation.handleMiddleware(context: context.build(),
                                                    input: input,
                                                    next: client.getHandler())
    }

    private var apiMetadata: AWSClientRuntime.APIMetadata {
        return AWSClientRuntime.APIMetadata(serviceId: "S3", version: "1.0")
    }

    private var sigv4Config: AWSClientRuntime.SigV4Config {
        return AWSClientRuntime.SigV4Config(signedBodyHeader: .contentSha256, unsignedBody: false)
    }

    private func createClient(config: AWSClientRuntime.AWSClientConfiguration) -> ClientRuntime.SdkHttpClient {
        return ClientRuntime.SdkHttpClient(engine: config.httpClientEngine, config: config.httpClientConfiguration)
    }

    private func createContext(config: AWSClientRuntime.AWSClientConfiguration,
                               method: HttpMethodType,
                               operation: String) -> ClientRuntime.HttpContextBuilder {
        let encoder = ClientRuntime.XMLEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = ClientRuntime.XMLDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.trimValueWhitespaces = false
        decoder.removeWhitespaceElements = true

        return ClientRuntime.HttpContextBuilder()
            .withEncoder(value: encoder)
            .withDecoder(value: decoder)
            .withMethod(value: method)
            .withServiceName(value: "S3")
            .withOperation(value: operation)
            .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
            .withLogger(value: config.logger)
            .withCredentialsProvider(value: config.credentialsProvider)
            .withRegion(value: config.region)
            .withSigningName(value: "s3")
            .withSigningRegion(value: config.signingRegion)
    }
}
