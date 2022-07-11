//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias AccessToken = String

struct DeleteUserEvent: StateMachineEvent {

    enum EventType {

        case deleteUser(AccessToken)

        case signOutDeletedUser

        case userSignedOutAndDeleted(SignedOutData)

        case throwError(AuthError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
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

    init(id: String = UUID().uuidString,
         eventType: EventType,
         time: Date? = nil) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

extension DeleteUserEvent.EventType: Equatable {

    static func == (lhs: DeleteUserEvent.EventType, rhs: DeleteUserEvent.EventType) -> Bool {
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
