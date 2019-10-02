//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension HubCategory: HubCategoryClientBehavior {
    /// Dispatch a Hub message on the specified channel
    /// - Parameter channel: The channel to send the message on
    /// - Parameter payload: The payload to send
    public func dispatch(to channel: HubChannel, payload: HubPayload) {
        plugin.dispatch(to: channel, payload: payload)
    }

    /// Listen to Hub messages on a particular channel, optionally filtering message prior to dispatching them
    ///
    /// - Parameter channel: The channel to listen for messages on
    /// - Parameter filter: If specified, candidate messages will be passed to this closure prior to dispatching to
    ///             the `listener` listener. Only messages for which the filter returns `true` will be dispatched.
    /// - Parameter listener: The closure to invoke with the received message
    public func listen(to channel: HubChannel,
                       isIncluded filter: HubFilter? = nil,
                       listener: @escaping HubListener) -> UnsubscribeToken {
        return plugin.listen(to: channel, isIncluded: filter, listener: listener)
    }

    /// Removes the listener identified by `token`
    /// - Parameter token: The UnsubscribeToken returned by `listen`
    public func removeListener(_ token: UnsubscribeToken) {
        plugin.removeListener(token)
    }

}
