//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//
import Foundation

/// Connection to make subscriptions
protocol SubscriptionConnection {

    /// Subscribe to the subscription request
    /// - Parameter variables: variables for the subscription
    /// - Parameter requestString: query for the subscription
    /// - Parameter eventHandler: event handler
    func subscribe(requestString: String,
                   variables: [String: Any]?,
                   eventHandler: @escaping SubscriptionEventHandler) -> SubscriptionItem

    /// Unsubscribe from the subscription
    /// - Parameter item: item to be unsubscribed
    func unsubscribe(item: SubscriptionItem)
}
