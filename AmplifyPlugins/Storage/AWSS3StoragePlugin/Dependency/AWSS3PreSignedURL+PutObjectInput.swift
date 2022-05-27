//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

//import AWSS3
//import ClientRuntime
//import AWSClientRuntime
//
//extension PutObjectInput {
//    func presignURL(config: AWSClientRuntime.AWSClientConfiguration, expiration: Swift.Int64) -> ClientRuntime.URL? {
//        let serviceName = "S3"
//        let input = self
//        let encoder = ClientRuntime.XMLEncoder()
//        encoder.dateEncodingStrategy = .secondsSince1970
//        let decoder = ClientRuntime.XMLDecoder()
//        decoder.dateDecodingStrategy = .secondsSince1970
//        decoder.trimValueWhitespaces = false
//        decoder.removeWhitespaceElements = true
//        let context = ClientRuntime.HttpContextBuilder()
//                      .withEncoder(value: encoder)
//                      .withDecoder(value: decoder)
//                      .withMethod(value: .put)
//                      .withServiceName(value: serviceName)
//                      .withOperation(value: "putObject")
//                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
//                      .withLogger(value: config.logger)
//                      .withCredentialsProvider(value: config.credentialsProvider)
//                      .withRegion(value: config.region)
//                      .withSigningName(value: "s3")
//                      .withSigningRegion(value: config.signingRegion)
//        var operation = ClientRuntime.OperationStack<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>(id: "putObject")
//        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>())
//        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>())
//        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.EndpointResolverMiddleware(endpointResolver: config.endpointResolver, serviceId: serviceName))
//        operation.serializeStep.intercept(position: .after, middleware: PutObjectInputBodyMiddleware())
//        operation.finalizeStep.intercept(position: .after, middleware: AWSClientRuntime.RetryerMiddleware(retryer: config.retryer))
//        let sigv4Config = AWSClientRuntime.SigV4Config(signatureType: .requestQueryParams, expiration: expiration, unsignedBody: true)
//        operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware(config: sigv4Config))
//        operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware(clientLogMode: config.clientLogMode))
//        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware())
//        let presignedRequestBuilder = operation.presignedRequest(context: context.build(), input: input, next: ClientRuntime.NoopHandler())
//        guard let builtRequest = presignedRequestBuilder?.build(), let presignedURL = builtRequest.endpoint.url else {
//            return nil
//        }
//        return presignedURL
//    }
//}
