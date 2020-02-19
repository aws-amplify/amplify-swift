//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SubscriptionState {

    case notSubscribed

    case inProgress

    case subscribed
}

public class AppSyncSubscriptionConnection: SubscriptionConnection, RetryableConnection {

    /// Connection provider that connects with the service
    weak var connectionProvider: ConnectionProvider?

    /// The current state of subscription
    var subscriptionState: SubscriptionState = .notSubscribed

    /// Current item that is subscriped
    var subscriptionItem: SubscriptionItem!

    /// Retry logic to handle
    var retryHandler: ConnectionRetryHandler?

    public init(provider: ConnectionProvider) {
        self.connectionProvider = provider
    }

    public func subscribe(requestString: String,
                   variables: [String: Any]?,
                   eventHandler: @escaping (SubscriptionItemEvent, SubscriptionItem) -> Void) -> SubscriptionItem {
        subscriptionItem = SubscriptionItem(requestString: requestString,
                                            variables: variables,
                                            eventHandler: eventHandler)
        addListener()
        subscriptionItem.subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        connectionProvider?.connect()
        return subscriptionItem
    }

    public func unsubscribe(item: SubscriptionItem) {
        AppSyncLogger.debug("Unsubscribe - \(item.identifier)")
        let message = AppSyncMessage(id: item.identifier,
                                     type: .unsubscribe("stop"))
        connectionProvider?.write(message)
        connectionProvider?.removeListener(identifier: subscriptionItem.identifier)
    }

    private func addListener() {
        connectionProvider?.addListener(identifier: subscriptionItem.identifier) { [weak self] event in
            guard let self = self else {
                AppSyncLogger.debug("Self is nil, listener is not called.")
                return
            }
            switch event {
            case .connection(let state):
                self.handleConnectionEvent(connectionState: state)
            case .data(let response):
                self.handleDataEvent(response: response)
            case .error(let error):
                self.handleError(error: error)
            }
        }
    }

    public func addRetryHandler(handler: ConnectionRetryHandler) {
        retryHandler = handler
    }
}
