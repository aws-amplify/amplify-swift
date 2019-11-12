//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Event handler for subscription.
typealias SubscriptionEventHandler<T> = (SubscriptionEvent<T>, SubscriptionItem) -> Void

/// Item that holds the subscription. This contains the raw query and variables.
class SubscriptionItem {

    /// Identifier for the subscription
    let identifier: String

    /// Subscription variables for the query
    let variables: [String: Any]?

    /// Request query for subscription
    let requestString: String

    /// State of the subscription
    var subscriptionConnectionState: SubscriptionConnectionState

    // Subscription related events will be send to this handler.
    let subscriptionEventHandler: SubscriptionEventHandler<Data>

    init(requestString: String,
         variables: [String: Any]?,
         subscriptionConnectionState: SubscriptionConnectionState = .disconnected,
         eventHandler: @escaping SubscriptionEventHandler<Data>) {

        self.identifier = UUID().uuidString
        self.variables = variables
        self.requestString = requestString
        self.subscriptionConnectionState = subscriptionConnectionState
        self.subscriptionEventHandler = eventHandler
    }

    func setState(_ subscriptionConnectionState: SubscriptionConnectionState) {
        self.subscriptionConnectionState = subscriptionConnectionState
        subscriptionEventHandler(.connection(self.subscriptionConnectionState), self)
    }

    func dispatch(data: Data) {
        subscriptionEventHandler(.data(data), self)
    }

    func dispatch(error: Error) {
        subscriptionEventHandler(.failed(error), self)
    }
}
