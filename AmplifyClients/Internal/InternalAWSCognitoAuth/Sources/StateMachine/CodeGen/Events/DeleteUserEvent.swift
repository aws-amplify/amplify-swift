//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package typealias AccessToken = String

package struct DeleteUserEvent: StateMachineEvent {

    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    package enum EventType: Sendable {

        /// `skipHostedUISignOut` is carried to the sign-out after the deletion (`SignOutEventData`). The
        /// plugin leaves it `false`; `AmplifyCognitoClient` sets it, since it never presents web UI from a
        /// deletion.
        case deleteUser(AccessToken, skipHostedUISignOut: Bool = false)

        case signOutDeletedUser(skipHostedUISignOut: Bool = false)

        case userSignedOutAndDeleted(SignedOutData)

        /// `cause` is carried to `DeleteUserState.error`.
        case throwError(EngineAuthError, cause: Error? = nil)

    }

    package let id: String
    package let eventType: EventType
    package let time: Date?

    package var type: String {
        switch eventType {
        case .deleteUser:
            return "DeleteUserEvent.deleteUser"
        case .signOutDeletedUser:
            return "DeleteUserEvent.signOutDeletedUser"
        case .userSignedOutAndDeleted:
            return "DeleteUserEvent.userSignedOutAndDeleted"
        case .throwError:
            return "DeleteUserEvent.throwError"
        }
    }

    package init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

extension DeleteUserEvent.EventType: Equatable {

    package static func == (lhs: DeleteUserEvent.EventType, rhs: DeleteUserEvent.EventType) -> Bool {
        switch (lhs, rhs) {

        case (.deleteUser, .deleteUser),
            (.signOutDeletedUser, .signOutDeletedUser),
            (.userSignedOutAndDeleted, .userSignedOutAndDeleted),
            (.throwError, .throwError):
            return true
        default: return false
        }

    }
}
