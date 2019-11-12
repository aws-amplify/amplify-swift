//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AppSyncConnectionProvider: MessageInterceptable {

    func addInterceptor(_ interceptor: MessageInterceptor) {
        messageInterceptors.append(interceptor)
    }

    // TODO: make interceptors async
    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage {
        let finalMessage = messageInterceptors.reduce(message) { $1.interceptMessage($0, for: endpoint) }
        return finalMessage
    }
}
