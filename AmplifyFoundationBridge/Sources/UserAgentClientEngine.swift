//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import ClientRuntime
import Foundation
import SmithyHTTPAPI

/// HTTP client engine wrapper that appends Amplify user-agent metadata to outgoing requests.
///
/// Appends `lib/amplify-swift#<version>` plus any additional metadata entries
/// to the `User-Agent` header.
///
/// Example usage:
/// ```swift
/// config.httpClientEngine = UserAgentClientEngine(
///     target: config.httpClientEngine,
///     additionalMetadata: ["md/amplify-kinesis"]
/// )
/// ```
public struct UserAgentClientEngine: HTTPClient {
    private let target: HTTPClient
    private let userAgentKey = "User-Agent"
    private let userAgentSuffix: String

    /// Creates a new user-agent engine wrapper.
    /// - Parameters:
    ///   - target: The underlying HTTP client engine to wrap.
    ///   - additionalMetadata: Optional metadata keys to append after `lib/amplify-swift#<version>`.
    ///     Each entry is appended as `<entry>#<version>`.
    public init(target: HTTPClient, additionalMetadata: [String] = []) {
        self.target = target
        let version = AmplifyMetadata.version
        var parts = ["lib/\(AmplifyMetadata.platformName)#\(version)"]
        for entry in additionalMetadata {
            parts.append("\(entry)#\(version)")
        }
        self.userAgentSuffix = parts.joined(separator: " ")
    }

    public func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
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
