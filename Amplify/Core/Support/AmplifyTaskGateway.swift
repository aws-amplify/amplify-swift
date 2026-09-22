//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Filtering was being handled by an Operation ID set up when subscribing. All elements dispatched with the
// operation would be filtered for the listener. AmplifyOperationContext is sent which passes the ID and
// the Request. HubPayload is made up of the eventName, context and the element which is being sent.

import Foundation

// Supports Hub and Async API
/// - Note: `Sendable` because the Hub listeners built in the extensions below close over `self`.
protocol AmplifyTaskGateway: Sendable {
    associatedtype Request: AmplifyOperationRequest
    associatedtype InProcess: Sendable
    associatedtype Success: Sendable
    associatedtype Failure: AmplifyError

    typealias TaskResult = Result<Success, Failure>
    typealias ResultListener = @Sendable (TaskResult) -> Void
    typealias InProcessListener = @Sendable (InProcess) -> Void

    var id: UUID { get }
    var request: Request { get }
    var categoryType: CategoryType { get }
    var eventName: HubPayloadEventName { get }

    var value: Success { get async throws }
    var result: TaskResult { get async }
    var inProcess: AmplifyAsyncSequence<InProcess> { get async }

    func pause()
    func resume()
    func cancel()

    func subscribe(resultListener: @escaping ResultListener) -> UnsubscribeToken
    func subscribe(inProcessListener: @escaping InProcessListener) -> UnsubscribeToken
    func unsubscribe(_ token: UnsubscribeToken)
    func dispatch(result: TaskResult)
    func dispatch(inProcess: InProcess)
}

extension AmplifyTaskGateway {
    var value: Success {
        get async throws {
            try await result.get()
        }
    }

    var idFilter: HubFilter {
        let filter: HubFilter = { payload in
            guard let context = payload.context as? AmplifyOperationContext<Request> else {
                return false
            }

            return context.operationId == id
        }

        return filter
    }

    func subscribe(resultListener: @escaping ResultListener) -> UnsubscribeToken {
        let channel = HubChannel(from: categoryType)
        let filterById = idFilter

        // The listener has to be able to remove itself, which means referencing a token that
        // does not exist until it is registered. Holding it in an `AtomicValue` lets the closure
        // capture an immutable box; capturing a `var` assigned afterwards is a reference to a
        // mutable variable from concurrently-executing code, rejected in Swift 6 language mode.
        let tokenBox = AtomicValue<UnsubscribeToken?>(initialValue: nil)
        let resultHubListener: HubListener = { payload in
            guard let result = payload.data as? TaskResult else {
                return
            }
            resultListener(result)
            // Automatically unsubscribe when event is received
            if let token = tokenBox.get() { Amplify.Hub.removeListener(token) }
        }
        let token = Amplify.Hub.listen(
            to: channel,
            isIncluded: filterById,
            listener: resultHubListener
        )
        tokenBox.set(token)
        return token
    }

    func subscribe(inProcessListener: @escaping InProcessListener) -> UnsubscribeToken {
        let channel = HubChannel(from: categoryType)
        let filterById = idFilter

        // The listener has to be able to remove itself, which means referencing a token that
        // does not exist until it is registered. Holding it in an `AtomicValue` lets the closure
        // capture an immutable box; capturing a `var` assigned afterwards is a reference to a
        // mutable variable from concurrently-executing code, rejected in Swift 6 language mode.
        let tokenBox = AtomicValue<UnsubscribeToken?>(initialValue: nil)
        let inProcessHubListener: HubListener = { payload in
            if let inProcessData = payload.data as? InProcess {
                inProcessListener(inProcessData)
                return
            }

            // Remove listener if we see a result come through
            if payload.data is TaskResult {
                if let token = tokenBox.get() { Amplify.Hub.removeListener(token) }
            }
        }
        let token = Amplify.Hub.listen(
            to: channel,
            isIncluded: filterById,
            listener: inProcessHubListener
        )
        tokenBox.set(token)
        return token
    }

    func unsubscribe(_ token: UnsubscribeToken) {
        Amplify.Hub.removeListener(token)
    }

    func dispatch(result: TaskResult) {
        let channel = HubChannel(from: categoryType)
        let context = AmplifyOperationContext(operationId: id, request: request)
        let payload = HubPayload(eventName: eventName, context: context, data: result)
        Amplify.Hub.dispatch(to: channel, payload: payload)
    }

    func dispatch(inProcess: InProcess) {
        let channel = HubChannel(from: categoryType)
        let context = AmplifyOperationContext(operationId: id, request: request)
        let payload = HubPayload(eventName: eventName, context: context, data: inProcess)
        Amplify.Hub.dispatch(to: channel, payload: payload)
    }

}
