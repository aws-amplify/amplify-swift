//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

@available(iOS 13.0, *)
public typealias HubPublisher = AnyPublisher<HubPayload, Never>

@available(iOS 13.0, *)
typealias HubSubject = PassthroughSubject<HubPayload, Never>

/// Maintains a map of Subjects by Hub Channel. All downstream subscribers will
/// attach to the same Subject.
@available(iOS 13.0, *)
private struct HubSubjectMap {
    static var `default` = HubSubjectMap()
    var subjectsByChannel = AtomicValue<[HubChannel: HubSubject]>(initialValue: [:])
}

@available(iOS 13.0, *)
extension HubCategoryBehavior {
    /// Returns a publisher for all Hub messages sent to `channel`
    ///
    /// - Parameter channel: The channel to listen for messages on
    public func publisher(for channel: HubChannel) -> HubPublisher {
        subject(for: channel).eraseToAnyPublisher()
    }

    /// Returns a HubSubject for `channel`
    ///
    /// - Parameter channel: the channel to retrieve the subject
    /// - Returns: a HubSubject used to send events on `channel`
    func subject(for channel: HubChannel) -> HubSubject {
        var sharedSubject: HubSubject!

        HubSubjectMap.default.subjectsByChannel.with { subjects in
            if let subject = subjects[channel] {
                sharedSubject = subject
                return
            }

            let subject = PassthroughSubject<HubPayload, Never>()
            subjects[channel] = subject
            sharedSubject = subject
        }

        return sharedSubject
    }

}
