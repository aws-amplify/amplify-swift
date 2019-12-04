//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Converts a connection request created with a standard endpoint configuration, to an AppSync Realtime Gateway
/// request by rewriting the URL.
class AppSyncSubscriptionInterceptor: ConnectionInterceptor {

    func interceptConnection(_ request: AppSyncConnectionRequest,
                             for url: URL) -> AppSyncConnectionRequest {
        guard let host = url.host else {
            Amplify.API.log.warn("[AppSyncSubscriptionInterceptor] interceptConnection missing host")
            return request
        }
        guard var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false) else {
            return request
        }
        // TODO: Move these constants from the constants file to this file where they're actually used
        // https://github.com/aws-amplify/amplify-ios/issues/75
        urlComponents.scheme = SubscriptionConstants.realtimeWebsocketScheme
        urlComponents.host = host.replacingOccurrences(of: SubscriptionConstants.appsyncHostPart,
                                                       with: SubscriptionConstants.appsyncRealtimeHostPart)
        guard let url = urlComponents.url else {
            return request
        }
        let realtimeRequest = AppSyncConnectionRequest(url: url)
        return realtimeRequest
    }
}
