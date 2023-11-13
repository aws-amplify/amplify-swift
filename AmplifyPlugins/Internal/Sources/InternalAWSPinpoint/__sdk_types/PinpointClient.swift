//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import Amplify

public struct PinpointClientConfiguration {
    let region: String
    let credentialsProvider: CredentialsProvider
    let signingName = "mobiletargeting"
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init(
        region: String,
        credentialsProvider: CredentialsProvider,
        encoder: () -> JSONEncoder = { JSONEncoder() },
        decoder: () -> JSONDecoder = { JSONDecoder() }
    ) {
        self.region = region
        self.credentialsProvider = credentialsProvider
        self.encoder = encoder()
        self.decoder = decoder()
    }

    // mobiletargeting
}

public struct PinpointClient {
    let configuration: PinpointClientConfiguration

    private func request<Input, Output>(
        action: PinpointAction<Input, Output>,
        input: Input,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) async throws -> Output {
        log.debug("[\(file)] [\(function)] [\(line)] request entry point")
        log.debug("[\(file)] [\(function)] [\(line)] input: \(input)")

        let requestData = try action.encode(input, configuration.encoder)
        log.debug("[\(file)] [\(function)] [\(line)] requestData size size: \(requestData.count)")

        log.debug("JSON String: \(String(requestData.prettyPrintedJSON ?? ""))")

        let url = try action.url(region: configuration.region)
        log.debug("[\(file)] [\(function)] [\(line)] unsigned request url: \(url)")
        let credentials = try await configuration.credentialsProvider.fetchCredentials()

        // TODO: generate user-agent
        let userAgent = "amplify-swift/2.x ua/2.0 api/logs#1.0 os/ios#17.0.1 lang/swift#5.8 cfg/retry-mode#legacy"
        log.debug("[\(file)] [\(function)] [\(line)] userAgent: \(userAgent)")

        let signer = SigV4Signer(
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
                "Accept": "application/json",
                "Content-Length": String(requestData.count),
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
            log.error("responseData: \(String(decoding: responseData, as: UTF8.self))")
            log.error("httpURLResponse: \(httpURLResponse)")
            throw try action.mapError(responseData, httpURLResponse)
        }

        log.debug("[\(file)] [\(function)] [\(line)] Attempting to decode response object in \(#function)")
        let response = try action.decode(responseData, configuration.decoder)
        log.debug("[\(file)] [\(function)] [\(line)] Decoded response in `\(Output.self)`: \(response)")

        return response
    }

//    #error("encoding nil Location")

    func updateEndpoint(input: UpdateEndpointInput) async throws -> UpdateEndpointOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .updateEndpoint(input: input),
            input: input
        )
    }

    func putEvents(input: PutEventsInput) async throws -> PutEventsOutputResponse {
        return try await request(
            action: .putEvents(input: input),
            input: input
        )
    }

    func deleteUserEndpoints(input: DeleteUserEndpointsInput) async throws -> DeleteUserEndpointsOutputResponse {
        return try await request(
            action: .deleteUserEndpoints(input: input),
            input: input
        )
    }
}

extension PinpointClient: DefaultLogger {
    public static let log: Logger = {
        Amplify.Logging.logger(
            forCategory: "Pinpoint",
            forNamespace: "PinpointClient"
        )
    }()

    public var log: Logger { Self.log }
}

extension Data {
    var prettyPrintedJSON: NSString? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .withoutEscapingSlashes]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}
