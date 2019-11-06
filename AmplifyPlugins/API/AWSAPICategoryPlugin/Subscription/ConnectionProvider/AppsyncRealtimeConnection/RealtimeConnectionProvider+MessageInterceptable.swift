//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension RealtimeConnectionProvider: MessageInterceptable {

    func addInterceptor(_ interceptor: MessageInterceptor) {
        messageInterceptors.append(interceptor)
    }

    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage {
        let finalMessage = messageInterceptors.reduce(message) { $1.interceptMessage($0, for: endpoint) }
        return finalMessage
    }
}
