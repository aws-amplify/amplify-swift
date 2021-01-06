//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

extension HubCategory: HubCategoryBehavior {
    public func dispatch(to channel: HubChannel, payload: HubPayload) {
        if #available(iOS 13.0, *) {
            Amplify.Hub.subject(for: channel).send(payload)
        }
        plugin.dispatch(to: channel, payload: payload)
    }

    public func listen(to channel: HubChannel,
                       eventName: HubPayloadEventName,
                       listener: @escaping HubListener) -> UnsubscribeToken {
        plugin.listen(to: channel, eventName: eventName, listener: listener)
    }

    public func listen(to channel: HubChannel,
                       isIncluded filter: HubFilter? = nil,
                       listener: @escaping HubListener) -> UnsubscribeToken {
        plugin.listen(to: channel, isIncluded: filter, listener: listener)
    }

    public func removeListener(_ token: UnsubscribeToken) {
        plugin.removeListener(token)
    }

}
