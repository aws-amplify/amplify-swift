//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

class MockHubCategoryPlugin: MessageReporter, HubCategoryPlugin {
    var key: String {
        return "MockHubCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() {
        notify("reset")
    }

    func dispatch(to channel: HubChannel, payload: HubPayload) {
        notify("dispatch")
    }

    func listen(to channel: HubChannel,
                eventName: HubPayloadEventName,
                listener: @escaping HubListener) -> UnsubscribeToken {
        notify("listenEventName")
        return UnsubscribeToken(channel: channel, id: UUID())
    }

    func listen(to channel: HubChannel,
                isIncluded filter: HubFilter?,
                listener: @escaping HubListener) -> UnsubscribeToken {
        notify("listen")
        return UnsubscribeToken(channel: channel, id: UUID())
    }

    func removeListener(_ token: UnsubscribeToken) {
        notify("removeListener")
    }
}

class MockSecondHubCategoryPlugin: MockHubCategoryPlugin {
    override var key: String {
        return "MockSecondHubCategoryPlugin"
    }
}
