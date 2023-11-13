//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import Amplify

struct RekognitionClient {
    struct Configuration {
        let region: String
        let credentialsProvider: CredentialsProvider
        let signingName = "rekognition"
        let encoder: JSONEncoder
        let decoder: JSONDecoder

        init(
            region: String,
            credentialsProvider: CredentialsProvider,
            encoder: () -> JSONEncoder = { JSONEncoder() },
            decoder: () -> JSONDecoder  = { JSONDecoder() }
        ) {
            self.region = region
            self.credentialsProvider = credentialsProvider
            self.encoder = encoder()
            self.decoder = decoder()
        }
    }

    let configuration: Configuration

    private func request<Input, Output>(
        action: RekognitionAction<Input, Output>,
        input: Input,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) async throws -> Output {
        log.debug("[\(file)] [\(function)] [\(line)] request entry point")
        log.debug("[\(file)] [\(function)] [\(line)] input: \(input)")

        let requestData = try action.encode(input, configuration.encoder)
        log.debug("[\(file)] [\(function)] [\(line)] requestData size size: \(requestData.count)")

        let url = try action.url(region: configuration.region)
        log.debug("[\(file)] [\(function)] [\(line)] unsigned request url: \(url)")
        let credentials = try await configuration.credentialsProvider.fetchCredentials()

        // TODO: generate user-agent
        let userAgent = "amplify-swift/2.x ua/2.0 api/logs#1.0 os/ios#17.0.1 lang/swift#5.8 cfg/retry-mode#legacy"
        log.debug("[\(file)] [\(function)] [\(line)] userAgent: \(userAgent)")

        let signer = AWSPluginsCore.SigV4Signer(
            credentials: credentials,
            serviceName: configuration.signingName,
            region: configuration.region
        )

        let signedRequest = signer.sign(
            url: url,
            method: action.method,
            body: .data(requestData),
            headers: [
                "Content-Type": "application/x-amz-json-1.1",
                "User-Agent": userAgent,
                "Accept": "application/json",
                "Content-Length": String(requestData.count),
                "X-Amz-Target": action.xAmzTarget
            ]
        )

        log.debug("[\(file)] [\(function)] [\(line)] Signed request URL: \(signedRequest)")
        log.debug("[\(file)] [\(function)] [\(line)] Signed request Headers: \(signedRequest.allHTTPHeaderFields as Any)")
        log.debug("[\(file)] [\(function)] [\(line)] Starting network request")

        let (responseData, urlResponse) = try await URLSession.shared.upload(
            for: signedRequest,
            from: requestData
        )
        log.debug("Completed network request in \(#function) with URLResponse: \(urlResponse)")

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            log.error("""
            Couldn't case from `URLResponse` to `HTTPURLResponse`
            This shouldn't happen. Received URLResponse: \(urlResponse)
            """)
            throw PlaceholderError() // this shouldn't happen
        }

        log.debug("[\(file)] [\(function)] [\(line)] HTTPURLResponse in \(#function): \(httpURLResponse)")
        guard (200..<300).contains(httpURLResponse.statusCode) else {
            log.error("Expected a 2xx status code, received: \(httpURLResponse.statusCode)")
            throw try action.mapError(responseData, httpURLResponse)
        }

        log.debug("[\(file)] [\(function)] [\(line)] Attempting to decode response object in \(#function)")
        log.debug("[\(file)] [\(function)] [\(line)] responseData: \(responseData)")
        log.debug("[\(file)] [\(function)] [\(line)] responseData.utf8: \(String(decoding: responseData, as: UTF8.self))")

        let response = try action.decode(responseData, configuration.decoder)
        log.debug("[\(file)] [\(function)] [\(line)] Decoded response in `\(Output.self)`: \(response)")

        return response
    }

    // application/x-amz-json-1.1"

    func recognizeCelebrities(input: RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutputResponse {
        try await request(action: .recognizeCelebrities(input: input), input: input)
    }

    func searchFacesByImage(input: SearchFacesByImageInput) async throws -> SearchFacesByImageOutputResponse {
        try await request(action: .searchFacesByImage(input: input), input: input)
    }

    func detectFaces(input: DetectFacesInput) async throws -> DetectFacesOutputResponse {
        try await request(action: .detectFaces(input: input), input: input)
    }

    func detectText(input: DetectTextInput) async throws -> DetectTextOutputResponse {
        try await request(action: .detectText(input: input), input: input)
    }

    func detectModerationLabels(input: DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutputResponse {
        try await request(action: .detectModerationLabels(input: input), input: input)
    }

    func detectLabels(input: DetectLabelsInput) async throws -> DetectLabelsOutputResponse {
        try await request(action: .detectLabels(input: input), input: input)
    }
}

extension RekognitionClient: DefaultLogger {
    public static let log: Logger = {
        Amplify.Logging.logger(
            forCategory: "Predictions",
            forNamespace: "ComprehendClient"
        )
    }()

    public var log: Logger { Self.log }
}