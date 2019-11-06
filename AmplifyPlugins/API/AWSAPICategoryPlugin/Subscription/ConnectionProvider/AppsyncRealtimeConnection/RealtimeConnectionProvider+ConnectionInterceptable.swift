//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension RealtimeConnectionProvider: ConnectionInterceptable {

    func addInterceptor(_ interceptor: ConnectionInterceptor) {
        connectionInterceptors.append(interceptor)
    }

    func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL) -> AppSyncConnectionRequest {
        let finalRequest = connectionInterceptors.reduce(request) { $1.interceptConnection($0, for: endpoint) }
        return finalRequest
    }
}
