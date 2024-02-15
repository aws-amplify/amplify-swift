//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(AmplifySwift) import AWSPluginsCore

/// General purpose authenticatication subscriptions interceptor for providers whose only
/// requirement is to provide an authentication token via the "Authorization" header
class CognitoAuthInterceptor {

    let getLatestAuthToken: () async throws -> String?

    init(getLatestAuthToken: @escaping () async throws -> String?) {
        self.getLatestAuthToken = getLatestAuthToken
    }

    init(authTokenProvider: AmplifyAuthTokenProvider) {
        self.getLatestAuthToken = authTokenProvider.getLatestAuthToken
    }

    private func getAuthToken() async -> AmplifyAuthTokenProvider.AuthToken? {
        try? await getLatestAuthToken()
    }
}

extension CognitoAuthInterceptor: AppSyncRequestInterceptor {
    func interceptRequest(event: AppSyncRealTimeRequest, url: URL) async -> AppSyncRealTimeRequest {
        guard case .start(let request) = event else {
            return event
        }

        guard let authToken = await getAuthToken() else {
            log.warn("Missing authentication token for subscription")
            return event
        }

        return .start(.init(
            id: request.id,
            data: request.data,
            auth: .cognito(.init(host: url.host!, authToken: authToken))
        ))
    }
}

extension CognitoAuthInterceptor: WebSocketInterceptor {
    func interceptConnection(url: URL) async -> URL {
        guard let authToken = await getAuthToken() else {
            log.warn("Missing authentication token for subscription request")
            return url
        }

        return AppSyncRealTimeRequestAuth.URLQuery(
            header: .cognito(.init(host: url.host!, authToken: authToken))
        ).withBaseURL(url)
    }
}

// MARK: AuthorizationTokenAuthInterceptor + DefaultLogger
extension CognitoAuthInterceptor: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
