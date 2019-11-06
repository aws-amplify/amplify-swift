//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Item that holds the subscription. This contains the raw query and variables.
struct SubscriptionItem {

    /// Identifier for the subscription
    let identifier: String

    /// Subscription variables for the query
    let variables: [String: Any]?

    /// Request query for subscription
    let requestString: String

    // Subscription related events will be send to this handler.
    let subscriptionEventHandler: SubscriptionEventHandler

    init(requestString: String,
         variables: [String: Any]?,
         eventHandler: @escaping SubscriptionEventHandler) {

        self.identifier = UUID().uuidString
        self.variables = variables
        self.requestString = requestString
        self.subscriptionEventHandler = eventHandler
    }
}

/// Event handler for subscription.
typealias SubscriptionEventHandler = (Event, SubscriptionItem) -> Void

/// Event for subscription
enum Event {
    /// Connect based event, the associated string will have connection message.
    case connection(SubscriptionConnectionEvent)

    /// Data event, the associated data contains the data received.
    case data(Data)

    /// Failure event, the associated error object contains the error occured.
    case failed(Error)

}

enum SubscriptionConnectionEvent {

     /// The subscription is in process of connecting
    case connecting

    /// The subscription has connected and is receiving events from the service
    case connected

    /// The subscription has been disconnected because of a lifecycle event or manual disconnect request
    case disconnected
}
