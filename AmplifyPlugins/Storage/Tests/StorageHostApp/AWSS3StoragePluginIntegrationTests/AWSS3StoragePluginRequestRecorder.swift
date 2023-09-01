//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSS3StoragePlugin

import ClientRuntime
import Foundation

class AWSS3StoragePluginRequestRecorder {
    var target: HttpClientEngine? = nil
    var sdkRequests: [SdkHttpRequest] = []
    var urlRequests: [URLRequest] = []
    init() {
    }
}

extension AWSS3StoragePluginRequestRecorder: HttpClientEngineProxy {
    func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        guard let target = target  else {
            throw ClientError.unknownError("HttpClientEngine is not set")
        }
        sdkRequests.append(request)
        return try await target.execute(request: request)
   }
}

extension AWSS3StoragePluginRequestRecorder: URLRequestDelegate {
    func willSend(request: URLRequest) {}
    func didSend(request: URLRequest) {
        urlRequests.append(request)
    }
}
