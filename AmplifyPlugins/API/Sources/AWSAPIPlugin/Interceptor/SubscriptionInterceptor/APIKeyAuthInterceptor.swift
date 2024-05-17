//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
@_spi(WebSocket) import InternalAmplifyNetwork

class APIKeyAuthInterceptor {
    private let apiKey: String
    private let getAuthHeader = authHeaderBuilder()

    init(apiKey: String) {
        self.apiKey = apiKey
    }

}

extension APIKeyAuthInterceptor: WebSocketInterceptor {
    func interceptConnection(url: URL) async -> URL {
        let authHeader = getAuthHeader(apiKey, AppSyncRealTimeClientFactory.appSyncApiEndpoint(url).host!)
        return AppSyncRealTimeRequestAuth.URLQuery(
            header: .apiKey(authHeader)
        ).withBaseURL(url)
    }
}

extension APIKeyAuthInterceptor: AppSyncRequestInterceptor {
    func interceptRequest(event: AppSyncRealTimeRequest, url: URL) async -> AppSyncRealTimeRequest {
        guard let host = AppSyncRealTimeClientFactory.appSyncApiEndpoint(url).host else {            
            return event
        }

        guard case .start(let request) = event else {
            return event
        }
        return .start(.init(
            id: request.id,
            data: request.data,
            auth: .apiKey(getAuthHeader(apiKey, host))
        ))
     }
}

fileprivate func authHeaderBuilder() -> (String, String) -> AppSyncRealTimeRequestAuth.ApiKey {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    return { apiKey, host in
        AppSyncRealTimeRequestAuth.ApiKey(
            host: host,
            apiKey: apiKey,
            amzDate: formatter.string(from: Date())
        )
    }

}
