//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct EndpointParameters {
    let endpoint: String
    let region: String
}

struct PlaceholderError: Error {}

// Placeholder Error
struct ServiceError: Error {
    let message: String?
    let type: String?
    let httpURLResponse: HTTPURLResponse
}

class LocationClient {
    let configuration: LocationClientConfiguration

    let log = AWSLocationGeoPlugin.log
    /*
     - encoder
     - decoder
     --- HTTPMethod
     - serviceName
     --- Operation
     --- idempotencyToken / - idempotencyTokenGenerator
     - logger
     - partitionID
     - credentialsProvider
     - region
     - signingName ("geo")
     - signingRegion
     */

    init(configuration: LocationClientConfiguration) {
        self.configuration = configuration
    }

    /*
     - build endpoint url
     - add headers:
        - user-agent: ...
        - Content-Type: application/json header
        - Signing Headers:
            - Host: ...
            - X-Amz-Date: ...
            - X-Amz-Security-Token: ...
            - Authorization: ...
        - Content-Length: <String(body.count)>
     - Add query items (if necessary)
     - Encode request body
     - Setup retry mechanism
     - sigv4 signing
     - make request
     - check for success status code
        - if failure: map to applicable error type
        - if success: decode responseData to expected response type
     */

    private func request<Input, Output>(
        action: Action<Input, Output>,
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
        let userAgent = "amplify-swift/2.x ua/2.0 api/location#1.0 os/ios#17.0.1 lang/swift#5.8 cfg/retry-mode#legacy"
        log.debug("[\(file)] [\(function)] [\(line)] userAgent: \(userAgent)")

        let signer = SigV4Signer(
            credentials: credentials,
            serviceName: configuration.signingName,
            region: configuration.region
        )

        let signedRequest = signer.sign(
            url: url,
            method: .post,
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
        let response = try action.decode(responseData, configuration.decoder)
        log.debug("[\(file)] [\(function)] [\(line)] Decoded response in `\(Output.self)`: \(response)")

        return response
    }

    func searchPlaceIndexForText(input: SearchPlaceIndexForTextInput) async throws -> SearchPlaceIndexForTextOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        guard let indexName = input.indexName else {
            // we need an index name
            throw PlaceholderError()
        }

        let action = Action.searchPlaceIndexForText(
            indexName: indexName.urlPercentEncoding()
        )

        return try await request(action: action, input: input)
    }

    func searchPlaceIndexForPosition(input: SearchPlaceIndexForPositionInput) async throws -> SearchPlaceIndexForPositionOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        guard let indexName = input.indexName else {
            // we need an index name
            throw PlaceholderError()
        }
        let action = Action.searchPlaceIndexForPosition(
            indexName: indexName.urlPercentEncoding()
        )

        return try await request(action: action, input: input)
    }
}
