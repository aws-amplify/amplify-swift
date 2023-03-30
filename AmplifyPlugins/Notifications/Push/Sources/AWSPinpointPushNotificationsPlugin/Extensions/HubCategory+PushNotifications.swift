//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension HubCategory {
    func dispatchRequestNotificationsPermissions(_ result: Bool) {
        let payload = HubPayload(
            eventName: HubPayload.EventName.Notifications.Push.requestNotificationsPermissions,
            data: result
        )
        dispatch(to: .pushNotifications, payload: payload)
    }

    func dispatchRequestNotificationsPermissions(_ error: Error) {
        let payload = HubPayload(
            eventName: HubPayload.EventName.Notifications.Push.requestNotificationsPermissions,
            data: error
        )
        dispatch(to: .pushNotifications, payload: payload)
    }
}
