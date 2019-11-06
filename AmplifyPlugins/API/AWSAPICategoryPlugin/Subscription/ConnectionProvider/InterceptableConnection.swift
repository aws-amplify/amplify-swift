//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Intercepts the connect request
protocol ConnectionInterceptable {

    /// Add a new interceptor to the object.
    ///
    /// - Parameter interceptor: interceptor to be added
    func addInterceptor(_ interceptor: ConnectionInterceptor)

    func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL) -> AppSyncConnectionRequest
}

protocol MessageInterceptable {

    func addInterceptor(_ interceptor: MessageInterceptor)

    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage
}

protocol ConnectionInterceptor {

    func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL) -> AppSyncConnectionRequest
}

protocol MessageInterceptor {

    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage
}
