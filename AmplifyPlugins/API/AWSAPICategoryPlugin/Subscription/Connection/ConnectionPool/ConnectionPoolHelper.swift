//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ConnectionPoolFactory {

    static func createConnectionProvider(for url: URL, connectionType: SubscriptionConnectionType) -> ConnectionProvider {
        switch connectionType {
        case .appSyncRealtime:
            let websocketProvider = StarscreamAdapter()
            let connectionProvider = RealtimeConnectionProvider(for: url, websocket: websocketProvider)
            return connectionProvider
        }
    }
}
