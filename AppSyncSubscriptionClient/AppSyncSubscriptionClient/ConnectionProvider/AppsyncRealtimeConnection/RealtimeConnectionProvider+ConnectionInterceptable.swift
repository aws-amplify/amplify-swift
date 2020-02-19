//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension RealtimeConnectionProvider: ConnectionInterceptable {

    public func addInterceptor(_ interceptor: ConnectionInterceptor) {
        connectionInterceptors.append(interceptor)
    }

    public func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL) -> AppSyncConnectionRequest {
        let finalRequest = connectionInterceptors.reduce(request) { $1.interceptConnection($0, for: endpoint) }
        return finalRequest
    }
}
