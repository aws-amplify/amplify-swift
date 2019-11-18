//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Connection to make subscriptions
protocol SubscriptionConnection {

    /// Subscribe to the subscription request
    /// - Parameter variables: variables for the subscription
    /// - Parameter requestString: query for the subscription
    /// - Parameter onEvent: event handler
    func subscribe(requestString: String,
                   variables: [String: Any]?,
                   onEvent: @escaping SubscriptionEventHandler<Data>) -> SubscriptionItem

    /// Unsubscribe from the subscription
    /// - Parameter item: item to be unsubscribed
    func unsubscribe(item: SubscriptionItem)
}
