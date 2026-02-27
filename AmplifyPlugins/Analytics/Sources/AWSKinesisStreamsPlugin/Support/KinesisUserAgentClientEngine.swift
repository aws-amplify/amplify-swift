//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation
import SmithyHTTPAPI

/// The version of the AWSKinesisStreamsPlugin, kept in sync with the Amplify Swift release.
/// CI updates this value during the release process.
let kinesisPluginVersion = "2.53.3"

/// HTTP client engine wrapper that appends `lib/amplify-swift#<version>` and
/// `md/kinesis#<version>` to the User-Agent header.
struct KinesisUserAgentClientEngine: HTTPClient {
    private let target: HTTPClient
    private let userAgentKey = "User-Agent"
    private let userAgentSuffix = "lib/amplify-swift#\(kinesisPluginVersion) md/kinesis#\(kinesisPluginVersion)"

    init(target: HTTPClient) {
        self.target = target
    }

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        let existingUserAgent = request.headers.value(for: userAgentKey) ?? ""
        let updatedUserAgent = "\(existingUserAgent) \(userAgentSuffix)"

        var headers = request.headers
        headers.remove(name: userAgentKey)
        headers.add(name: userAgentKey, value: updatedUserAgent)

        let endpoint = SmithyHTTPAPI.Endpoint(
            uri: request.endpoint.uri,
            headers: headers
        )

        let updatedRequest = HTTPRequest(
            method: request.method,
            endpoint: endpoint,
            body: request.body
        )

        return try await target.send(request: updatedRequest)
    }
}
