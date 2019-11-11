//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify

/// Connection to make subscriptions
protocol SubscriptionConnection {

    func subscribe<R: Decodable>(request: GraphQLRequest,
                                 responseType: R.Type,
                                 listener: @escaping SubscriptionEventHandler<R>) -> SubscriptionOperation<R>

    /// Unsubscribe from the subscription
    /// - Parameter item: item to be unsubscribed
    func unsubscribe(_ identifier: String)
}
