//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify

protocol AmplifyAuthTask {

    associatedtype Success
    associatedtype Request
    associatedtype Failure: AmplifyError

    typealias AmplifyAuthTaskResult = Result<Success, Failure>

    var value: Success { get async throws }

    var eventName: HubPayloadEventName { get }

    func execute() async throws -> Success

    func dispatch(result: AmplifyAuthTaskResult)

}

extension AmplifyAuthTask {
    var value: Success {
        get async throws {
            do {
                let valueReturned = try await execute()
                dispatch(result: .success(valueReturned))
                return valueReturned
            } catch let error as Failure {
                dispatch(result: .failure(error))
                throw error
            }
        }
    }

    func dispatch(result: AmplifyAuthTaskResult) {
        let channel = HubChannel(from: .auth)
        let payload = HubPayload(eventName: eventName, context: nil, data: result)
        Amplify.Hub.dispatch(to: channel, payload: payload)
    }
}
