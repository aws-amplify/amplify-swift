//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSS3StoragePlugin

import Foundation
import Smithy
import SmithyHTTPAPI

// `@unchecked Sendable`: mutable state is guarded by `lock`; upload parts record requests concurrently.
final class AWSS3StoragePluginRequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _target: HTTPClient?
    private var _sdkRequests: [HTTPRequest] = []
    private var _urlRequests: [URLRequest] = []

    var target: HTTPClient? {
        get { lock.withLock { _target } }
        set { lock.withLock { _target = newValue } }
    }

    var sdkRequests: [HTTPRequest] { lock.withLock { _sdkRequests } }
    var urlRequests: [URLRequest] { lock.withLock { _urlRequests } }

    init() {
    }
}

extension AWSS3StoragePluginRequestRecorder: HttpClientEngineProxy {
    func send(request: HTTPRequest) async throws -> HTTPResponse {
        guard let target  else {
            throw ClientError.unknownError("HttpClientEngine is not set")
        }
        lock.withLock { _sdkRequests.append(request) }
        return try await target.send(request: request)
   }
}

extension AWSS3StoragePluginRequestRecorder: URLRequestDelegate {
    func willSend(request: URLRequest) {}
    func didSend(request: URLRequest) {
        lock.withLock { _urlRequests.append(request) }
    }
}
