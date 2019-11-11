//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

enum SubscriptionState {

    case connecting

    case connected

    case disconnected
}

class AppSyncSubscriptionConnection: SubscriptionConnection, RetryableConnection {

    /// Provides a way to connect, disconnect, and send messages to the service.
    let connectionProvider: ConnectionProvider

    /// Map of all subscriptions on this connection
    var subscriptionItems: [String: SubscriptionItem] = [:]

    /// Retry logic to handle
    var retryHandler: ConnectionRetryHandler?

    convenience init(url: URL, interceptor: AuthInterceptor) {
        let connectionProvider = AppSyncConnectionProvider(for: url, interceptor: interceptor)
        connectionProvider.addInterceptor(interceptor)
        self.init(connectionProvider: connectionProvider)
    }

    init(connectionProvider: ConnectionProvider) {
        self.connectionProvider = connectionProvider

        connectionProvider.setListener { [weak self] (event) in
            guard let self = self else {
                return
            }

            self.onConnectionProviderEvent(event: event)
        }
    }

    func subscribe(requestString: String,
                   variables: [String: Any]?,
                   eventHandler: @escaping SubscriptionEventHandler<Data>) -> SubscriptionItem {

        let subscriptionItem = SubscriptionItem(requestString: requestString,
                                                variables: variables,
                                                eventHandler: eventHandler)
        subscriptionItems[subscriptionItem.identifier] = subscriptionItem
        connectionProvider.connect()

        return subscriptionItem
    }

    func unsubscribe(item: SubscriptionItem) {
        print("Unsubscribe - \(item.identifier)")
        connectionProvider.sendUnsubscribeMessage(identifier: item.identifier)
        // TODO: find where the message comes back, and remove the mapping to subscriptionItem.
        //ie. subscriptionItems[item.identifier] = nil
    }

    func addRetryHandler(handler: ConnectionRetryHandler) {
        retryHandler = handler
    }
}
