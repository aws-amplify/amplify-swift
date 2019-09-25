//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension HubCategory: HubCategoryClientBehavior {
    public func dispatch(to channel: HubChannel, payload: HubPayload) {
        plugin.dispatch(to: channel, payload: payload)
    }

    public func listen(to channel: HubChannel,
                       filteringWith filter: HubFilter? = nil,
                       onEvent: @escaping HubListener) -> UnsubscribeToken {
        return plugin.listen(to: channel, filteringWith: filter, onEvent: onEvent)
    }

    public func removeListener(_ token: UnsubscribeToken) {
        plugin.removeListener(token)
    }

}
