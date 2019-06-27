//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Convenience typealias defining a closure that can be used to filter Hub messages
public typealias HubFilter = (HubPayload) -> Bool

/// Convenience typealias defining a closure that can be used to listen to Hub messages
public typealias HubListener = (HubPayload) -> Void

/// Convenience typealias defining a closure that can be used to unsubscribe a Hub listener
public typealias UnsubscribeToken = UUID

/// Behavior of the Hub category that clients will use
public protocol HubCategoryClientBehavior {

    /// Dispatch a Hub message on the specified channel
    /// - Parameter channel: The channel to send the message on
    /// - Parameter payload: The payload to send
    func dispatch(to channel: HubChannel, payload: HubPayload)

    /// Listen to Hub messages on a particular channel, optionally filtering message prior to dispatching them
    /// - Parameter channel: The channel to listen for messages on. **NOTE** Failing to specify a channel may result in
    ///             a large volume of messages being delivered to the filter and the listener.
    /// - Parameter filter: If specified, candidate messages will be passed to this closure prior to dispatching to
    ///             the `onEvent` listener. Only messages for which the filter returns `true` will be dispatched.
    /// - Parameter onEvent: The closure to invoke with the received message
    func listen(to channel: HubChannel?,
                filteringWith filter: @escaping HubFilter,
                onEvent: @escaping HubListener) -> UnsubscribeToken

    /// Removes the listener identified by `token`
    /// - Parameter token: The UnsubscribeToken returned by `listen`
    func removeListener(_ token: UnsubscribeToken)
}
