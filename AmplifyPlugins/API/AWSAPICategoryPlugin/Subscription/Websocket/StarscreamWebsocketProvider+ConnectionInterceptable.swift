//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension StarscreamWebsocketProvider: ConnectionInterceptable {
    func addInterceptor(_ interceptor: ConnectionInterceptor) {
        connectionInterceptors.append(interceptor)
    }

    // TODO: Make interceptors asynchronous
    func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL) -> AppSyncConnectionRequest {
        let finalRequest = connectionInterceptors.reduce(request) { $1.interceptConnection($0, for: endpoint) }
        return finalRequest
    }
}
