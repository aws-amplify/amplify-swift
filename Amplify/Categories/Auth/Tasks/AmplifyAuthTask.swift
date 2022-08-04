//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(Combine)
import Combine
#endif

open class AmplifyAuthTask<Success, Failure: AmplifyError> {
#if canImport(Combine)
    var resultFuture: Any
    var resultPromise: Any
#endif
    
    /// The concrete Success type associated with this operation
    public typealias Success = Success

    /// The concrete Failure type associated with this operation
    public typealias Failure = Failure

    /// Convenience typealias defining the `Result`s dispatched by this operation
    public typealias AuthTaskResult = Result<Success, Failure>

    /// All AmplifyOperations must declare a HubPayloadEventName
    public let eventName: HubPayloadEventName
    
    public init(eventName: HubPayloadEventName) {
        self.eventName = eventName

#if canImport(Combine)
        self.resultFuture = false
        self.resultPromise = false
        resultFuture = Future<Success, Failure> { self.resultPromise = $0 }
#endif
    }

    /// Dispatches an event to the hub. Internally, creates an
    /// `AmplifyOperationContext` object from the operation's `id`, and `request`. On
    /// iOS 13+, this method also publishes the result on the `resultPublisher`.
    ///
    /// - Parameter result: The OperationResult to dispatch to the hub as part of the
    ///   HubPayload
    public func dispatch(result: AuthTaskResult) {
        let channel = HubChannel(from: .auth)
        let payload = HubPayload(eventName: eventName, context: nil, data: result)
        Amplify.Hub.dispatch(to: channel, payload: payload)
        
#if canImport(Combine)
        publish(result: result)
#endif
    }
}
