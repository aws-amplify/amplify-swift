//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AppSyncSubscriptionConnection: SubscriptionConnection, RetryableConnection {

    let identifier = UUID().uuidString

    /// Provides a way to connect and subscribe to the connection
    let connectionProvider: ConnectionProvider

    /// Retry logic to handle connection failuress
    var retryHandler: ConnectionRetryHandler?

    // Queue containing all subscriptions connected to the websocket connection
    let queue: OperationQueue = OperationQueue()

    convenience init(url: URL, interceptor: AuthInterceptor) {
        let connectionProvider = AppSyncConnectionProvider(for: url, interceptor: interceptor)
        connectionProvider.addInterceptor(interceptor)
        self.init(connectionProvider: connectionProvider)
    }

    init(connectionProvider: ConnectionProvider) {
        self.connectionProvider = connectionProvider

        connectionProvider.addListener(identifier) { [weak self] (event) in
            guard let self = self else {
                return
            }

            self.onConnectionProviderEvent(event: event)
        }
    }

    func subscribe<R: Decodable>(request: GraphQLRequest,
                                 responseType: R.Type,
                                 listener: @escaping SubscriptionEventListener<R>) -> SubscriptionOperation<R> {

        let operation = SubscriptionOperation(request: request,
                                              responseType: responseType,
                                              connectionProvider: connectionProvider,
                                              listener: listener)
        queue.addOperation(operation)
        return operation
    }

    func unsubscribe(item: SubscriptionItem) {
        print("Unsubscribe - \(item.identifier)")
        connectionProvider.unsubscribe(item.identifier)
    }

    func addRetryHandler(handler: ConnectionRetryHandler) {
        retryHandler = handler
    }
}
