//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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
