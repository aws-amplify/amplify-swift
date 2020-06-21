//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

public typealias HubPublisher = AnyPublisher<HubPayload, Never>

/// Maintains a map of Publishers by Hub Channel, so we can share multiple downstream subscribers with a single
/// subscription to the Hub. Note that this will register a hub listener for the channel for the duration of the app
/// lifespan
private struct HubListenerMap {
    static var `default` = HubListenerMap()
    var publishers = AtomicValue<[HubChannel: HubPublisher]>(initialValue: [:])
}

public extension HubCategoryBehavior {

    /// Returns a publisher for all Hub messages on a particular channel
    ///
    /// - Parameter channel: The channel to listen for messages on
    func publisher(for channel: HubChannel) -> HubPublisher {
        var sharedPublisher: HubPublisher!

        HubListenerMap.default.publishers.with { publishers in
            if publishers[channel] != nil {
                sharedPublisher = publishers[channel]!
                return
            }

            let subject = PassthroughSubject<HubPayload, Never>()
            _ = Amplify.Hub.listen(to: channel) { payload in
                subject.send(payload)
            }

            sharedPublisher = subject.eraseToAnyPublisher()
            publishers[channel] = sharedPublisher
        }

        return sharedPublisher
    }

}
