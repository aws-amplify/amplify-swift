//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(WebSocket) import AWSPluginsCore

/// General purpose authenticatication subscriptions interceptor for providers whose only
/// requirement is to provide an authentication token via the "Authorization" header
class AuthTokenInterceptor {

    let getLatestAuthToken: () async throws -> String?

    init(getLatestAuthToken: @escaping () async throws -> String?) {
        self.getLatestAuthToken = getLatestAuthToken
    }

    init(authTokenProvider: AmplifyAuthTokenProvider) {
        self.getLatestAuthToken = authTokenProvider.getLatestAuthToken
    }

    private func getAuthToken() async -> AmplifyAuthTokenProvider.AuthToken {
        // A user that is not signed in should receive an unauthorized error from
        // the connection attempt. This code achieves this by always creating a valid
        // request to AppSync even when the token cannot be retrieved. The request sent
        // to AppSync will receive a response indicating the request is unauthorized.
        // If we do not use empty token string and perform the remaining logic of the
        // request construction then it will fail request validation at AppSync before
        // the authorization check, which ends up being propagated back to the caller
        // as a "bad request". Example of bad requests are when the header and payload
        // query strings are missing or when the data is not base64 encoded.
        (try? await getLatestAuthToken()) ?? ""
    }
}

extension AuthTokenInterceptor: AppSyncRequestInterceptor {
    func interceptRequest(event: AppSyncRealTimeRequest, url: URL) async -> AppSyncRealTimeRequest {
        guard case .start(let request) = event else {
            return event
        }

        let authToken = await getAuthToken()

        return .start(.init(
            id: request.id,
            data: request.data,
            auth: .authToken(.init(
                host: AppSyncRealTimeClientFactory.appSyncApiEndpoint(url).host!,
                authToken: authToken
            ))
        ))
    }
}

extension AuthTokenInterceptor: WebSocketInterceptor {
    func interceptConnection(request: URLRequest) async -> URLRequest {
        guard let url = request.url else { return request }
        let authToken = await getAuthToken()

        return request.injectAppSyncAuthToRequestHeader(
            auth: .authToken(.init(
                host: AppSyncRealTimeClientFactory.appSyncApiEndpoint(url).host!,
                authToken: authToken
            )
        ))
    }
}

// MARK: AuthorizationTokenAuthInterceptor + DefaultLogger
extension AuthTokenInterceptor: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
