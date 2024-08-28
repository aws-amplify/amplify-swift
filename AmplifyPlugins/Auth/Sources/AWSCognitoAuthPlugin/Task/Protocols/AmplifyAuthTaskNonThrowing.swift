//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol AmplifyAuthTaskNonThrowing {

    associatedtype Success
    associatedtype Request

    var value: Success { get async }

    var eventName: HubPayloadEventName { get }

    func execute() async -> Success

    func dispatch(result: Success)

}

extension AmplifyAuthTaskNonThrowing where Self: DefaultLogger {
    var value: Success {
        get async {
            log.info("Starting execution for \(eventName)")
            let valueReturned = await execute()
            log.info("Successfully completed execution for \(eventName) with result:\n\(valueReturned)")
            dispatch(result: valueReturned)
            return valueReturned
        }
    }

    func dispatch(result: Success) {

        let channel = HubChannel(from: .auth)
        let payload = HubPayload(eventName: eventName, context: nil, data: result)
        Amplify.Hub.dispatch(to: channel, payload: payload)
    }
}
