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

class AWSS3StoragePluginRequestRecorder {
    var target: HTTPClient? = nil
    var sdkRequests: [HTTPRequest] = []
    var urlRequests: [URLRequest] = []
    init() {
    }
}

extension AWSS3StoragePluginRequestRecorder: HttpClientEngineProxy {
    func send(request: HTTPRequest) async throws -> HTTPResponse {
        guard let target = target  else {
            throw ClientError.unknownError("HttpClientEngine is not set")
        }
        sdkRequests.append(request)
        return try await target.send(request: request)
   }
}

extension AWSS3StoragePluginRequestRecorder: URLRequestDelegate {
    func willSend(request: URLRequest) {}
    func didSend(request: URLRequest) {
        urlRequests.append(request)
    }
}
