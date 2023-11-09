//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import Amplify

struct PollyClient {
    struct Configuration {
        let region: String
        let credentialsProvider: CredentialsProvider
        let signingName = "polly"
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
        action: PollyAction<Input, Output>,
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
                "Content-Type": "application/json",
                "User-Agent": userAgent,
                "Content-Length": String(requestData.count)
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


    func synthesizeSpeech(input: SynthesizeSpeechInput) async throws -> SynthesizeSpeechOutputResponse {
        let action = PollyAction.synthesizeSpeech(input: input)
        let file = #file, function = #function, line = #line
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
                "Content-Type": "application/json",
                "User-Agent": userAgent,
                "Content-Length": String(requestData.count)
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

        let response = SynthesizeSpeechOutputResponse(audioStream: responseData)
//        let response = try action.decode(responseData, configuration.decoder)

        return response
    }
}

extension PollyClient: DefaultLogger {
    public static let log: Logger = {
        Amplify.Logging.logger(
            forCategory: "Predictions",
            forNamespace: "PollyClient"
        )
    }()

    public var log: Logger { Self.log }
}
