//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

open class AmplifyAuthTask<Request, Success, Failure: AmplifyError> {
    public typealias Success = Success
    public typealias Request = Request
    public typealias Failure = Failure
    public typealias AmplifyAuthTaskResult = Result<Success, Failure>
    
    open var value: Success {
        get async throws {
            throw AuthError.service("Invalid Auth Task value", "", nil)
        }
    }

    /// All AmplifyOperations must declare a HubPayloadEventName
    public let eventName: HubPayloadEventName

    public init(eventName: HubPayloadEventName) {
        self.eventName = eventName
    }
    
    /// Dispatches an event to the hub. Internally, creates an
    /// `AmplifyOperationContext` object from the operation's `id`, and `request`. On
    /// iOS 13+, this method also publishes the result on the `resultPublisher`.
    ///
    /// - Parameter result: The AmplifyAuthTaskResult to dispatch to the hub as part of the
    ///   HubPayload
    public func dispatch(result: AmplifyAuthTaskResult) {
        let channel = HubChannel(from: .auth)
        let payload = HubPayload(eventName: eventName, context: nil, data: result)
        Amplify.Hub.dispatch(to: channel, payload: payload)
    }

}
