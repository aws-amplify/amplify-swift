//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AppSyncSubscriptionConnection: SubscriptionConnection, RetryableConnection {

    /// Provides a way to connect, disconnect, and send messages to the service.
    let connectionProvider: ConnectionProvider

    /// Map of all subscription created on this connection
    var subscriptionItems: [String: SubscriptionItem] = [:]

    /// Retry logic to handle connection failuress
    var retryHandler: ConnectionRetryHandler?

    /// Serial queue for maintaining the access to SubscriptionItems
    let serialSubscriptionQueue = DispatchQueue(label: "com.amazonaws.AppSyncSubscriptionConnection.serialQueue")

    convenience init(url: URL, interceptor: AuthInterceptor) {
        let connectionProvider = AppSyncConnectionProvider(for: url, interceptor: interceptor)
        connectionProvider.addInterceptor(interceptor)
        self.init(connectionProvider: connectionProvider)
    }

    init(connectionProvider: ConnectionProvider) {
        self.connectionProvider = connectionProvider

        connectionProvider.setListener { [weak self] event in
            guard let self = self else {
                return
            }

            self.onConnectionProviderEvent(event: event)
        }
    }

    func subscribe(requestString: String,
                   variables: [String: Any]?,
                   onEvent: @escaping SubscriptionEventHandler<Data>) -> SubscriptionItem {

        let subscriptionItem = SubscriptionItem(requestString: requestString,
                                                variables: variables,
                                                onEvent: onEvent)
        serialSubscriptionQueue.async {[weak self] in
            self?.subscriptionItems[subscriptionItem.identifier] = subscriptionItem
        }

        if connectionProvider.isConnected {
            connectionProvider.subscribe(subscriptionItem)
        } else {
            connectionProvider.connect()
        }

        return subscriptionItem
    }

    func unsubscribe(item: SubscriptionItem) {
        Amplify.API.log.verbose("Unsubscribe - \(item.identifier)")
        connectionProvider.unsubscribe(item.identifier)
    }

    func addRetryHandler(handler: ConnectionRetryHandler) {
        retryHandler = handler
    }
}
