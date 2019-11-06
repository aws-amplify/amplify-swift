//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Connection interceptor for real time connection provider
class RealtimeGatewayURLInterceptor: ConnectionInterceptor {

    func interceptConnection(_ request: AppSyncConnectionRequest,
                             for endpoint: URL) -> AppSyncConnectionRequest {
        guard let host = endpoint.host else {
            return request
        }
        guard var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false) else {
            return request
        }
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
