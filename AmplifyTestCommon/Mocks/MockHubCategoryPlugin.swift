//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

// `@unchecked Sendable` because the category plugin protocols now require `Sendable` (see
// `Plugin`), and a `Sendable` class may not inherit from a non-`NSObject` superclass. These are
// test doubles driven from a single test at a time.
class MockHubCategoryPlugin: MessageReporter, HubCategoryPlugin, @unchecked Sendable {
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
        notify("\(payload.eventName)")
    }

    func listen(
        to channel: HubChannel,
        eventName: HubPayloadEventName,
        listener: @escaping HubListener
    ) -> UnsubscribeToken {
        notify("listenEventName")
        return UnsubscribeToken(channel: channel, id: UUID())
    }

    func listen(
        to channel: HubChannel,
        isIncluded filter: HubFilter?,
        listener: @escaping HubListener
    ) -> UnsubscribeToken {
        notify("listen")
        return UnsubscribeToken(channel: channel, id: UUID())
    }

    func removeListener(_ token: UnsubscribeToken) {
        notify("removeListener")
    }
}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double.

class MockSecondHubCategoryPlugin: MockHubCategoryPlugin, @unchecked Sendable {
    override var key: String {
        return "MockSecondHubCategoryPlugin"
    }
}
