//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import AWSPluginsCore
import ClientRuntime
import AWSClientRuntime

/// The class confirming to AWSS3PreSignedURLBuilderBehavior which uses GetObjectInput to
/// create a pre-signed URL.
class AWSS3PreSignedURLBuilderAdapter: AWSS3PreSignedURLBuilderBehavior {
    let defaultExpiration: Int64 = 50 * 60 // 50 minutes

    let bucket: String
    let config: AWSClientConfiguration
    let logger: Logger

    /// Creates a pre-signed URL builder.
    /// - Parameter credentialsProvider: Credentials Provider.
    init(config: S3Client.S3ClientConfiguration, bucket: String, logger: Logger = storageLogger) {
        self.bucket = bucket
        self.config = config
        self.logger = logger
    }

    /// Gets pre-signed URL.
    /// - Returns: Pre-Signed URL
    func getPreSignedURL(key: String, method: AWSS3HttpMethod, expires: Int64? = nil) -> URL? {
        let expiresDate = Date(timeIntervalSinceNow: Double(expires ?? defaultExpiration))
        let expiration = Int64(expiresDate.timeIntervalSinceNow)
        let preSignedUrl: URL?
        switch method {
        case .get:
            let input = GetObjectInput(bucket: bucket, key: key)
            preSignedUrl = input.presignURL(config: config, expiration: expiration)
        case .put:
            let input = PutObjectInput(bucket: bucket, key: key)
            preSignedUrl = input.presignURL(config: config, expiration: expiration)
        }
        return urlWithEscapedToken(preSignedUrl)
    }

    private func urlWithEscapedToken(_ url: URL?) -> URL? {
        print("Received URL: \(url?.absoluteString ?? "nil")")
        guard let url = url,
              var components = URLComponents(string: url.absoluteString),
              var token = components.queryItems?.first(where: { $0.name == "X-Amz-Security-Token" }) else {
                  return nil
              }
        token.value = token.value?.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        components.port = nil
        components.percentEncodedQueryItems?.removeAll(where: { $0.name == "X-Amz-Security-Token" })
        components.percentEncodedQueryItems?.append(token)
        return components.url
    }
}

private extension PutObjectInput {
    func presignURL(config: AWSClientRuntime.AWSClientConfiguration, expiration: Swift.Int64) -> ClientRuntime.URL? {
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
                      .withMethod(value: .put)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "putObject")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withCredentialsProvider(value: config.credentialsProvider)
                      .withRegion(value: config.region)
                      .withSigningName(value: "s3")
                      .withSigningRegion(value: config.signingRegion)
        var operation = ClientRuntime.OperationStack<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>(id: "putObject")
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>())
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>())
        operation.buildStep.intercept(position: .before, middleware: AWSClientRuntime.EndpointResolverMiddleware(endpointResolver: config.endpointResolver, serviceId: serviceName))
        operation.serializeStep.intercept(position: .after, middleware: PutObjectInputBodyMiddleware())
        operation.finalizeStep.intercept(position: .after, middleware: AWSClientRuntime.RetryerMiddleware(retryer: config.retryer))
        let sigv4Config = AWSClientRuntime.SigV4Config(signatureType: .requestQueryParams, expiration: expiration, unsignedBody: true)
        operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware(config: sigv4Config))
        operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware(clientLogMode: config.clientLogMode))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware())
        let presignedRequestBuilder = operation.presignedRequest(context: context.build(), input: input, next: ClientRuntime.NoopHandler())
        guard let builtRequest = presignedRequestBuilder?.build(), let presignedURL = builtRequest.endpoint.url else {
            return nil
        }
        return presignedURL
    }
}
