//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct PushNotification {
    private init() {}

    typealias UserInfo = [AnyHashable: Any]

    struct Payload {
        let source: Source
        let attributes: [String: String]
    }

    enum Source: String {
        case journey
        case campaign
    }

    enum Action: Equatable {
        case opened
        case received(state: ApplicationState)

        var eventType: String {
            switch self {
            case .opened:
                return "opened_notification"
            case .received(state: let state):
                switch state {
                case .foreground:
                    return "received_foreground"
                case .background,
                     .inactive:
                    return "received_background"
                }
            }
        }
    }
}
