//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// HubChannel represents the channels on which Amplify category messages will be dispatched. Apps can define their own
/// channels for intra-app communication. Internally, Amplify uses the Hub for dispatching notifications about events
/// associated with different categories.
public enum HubChannel {
    /// Hub messages relating to Amplify Storage
    case storage

    /// A custom channel with its own name
    case custom(String)

    /// Convenience property to return an array of all non-`custom` channels
    static var amplifyChannels: [HubChannel] {
        return [
            .storage
        ]
    }
}

extension HubChannel: Equatable {
    public static func == (lhs: HubChannel, rhs: HubChannel) -> Bool {
        switch (lhs, rhs) {
        case (.storage, .storage):
            return true

        case (.custom(let lhsValue), .custom(let rhsValue)):
            return lhsValue == rhsValue

        default:
            return false
        }
    }
}
