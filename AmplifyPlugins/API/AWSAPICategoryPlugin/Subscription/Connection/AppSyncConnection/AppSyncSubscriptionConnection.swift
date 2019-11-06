//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

enum SubscriptionState {

    case notSubscribed

    case inProgress

    case subscribed
}

class AppSyncSubscriptionConnection: SubscriptionConnection, RetryableConnection {

    /// Connection provider that connects with the service
    weak var connectionProvider: ConnectionProvider?

    /// The current state of subscription
    var subscriptionState: SubscriptionState = .notSubscribed

    /// Current item that is subscriped
    var subscriptionItem: SubscriptionItem!

    /// Retry logic to handle
    var retryHandler: ConnectionRetryHandler?

    init(provider: ConnectionProvider) {
        self.connectionProvider = provider
    }

    func subscribe(requestString: String,
                   variables: [String: Any]?,
                   eventHandler: @escaping (Event, SubscriptionItem) -> Void) -> SubscriptionItem {
        subscriptionItem = SubscriptionItem(requestString: requestString,
                                            variables: variables,
                                            eventHandler: eventHandler)
        addListener()
        connectionProvider?.connect()
        subscriptionItem.subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        return subscriptionItem
    }

    func unsubscribe(item: SubscriptionItem) {
        print("Unsubscribe - \(item.identifier)")
        let message = AppSyncMessage(id: item.identifier,
                                     type: .unsubscribe("stop"))
        connectionProvider?.write(message)
    }

    private func addListener() {
        connectionProvider?.addListener { [weak self] (event) in
            guard let self = self else {
                print("Self is nil, listener is not called.")
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

    func addRetryHandler(handler: ConnectionRetryHandler) {
        retryHandler = handler
    }
}
