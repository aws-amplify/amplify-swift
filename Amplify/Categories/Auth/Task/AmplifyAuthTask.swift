//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public protocol AmplifyAuthTaskRefactored {

    associatedtype Success
    associatedtype Request
    associatedtype Failure: AmplifyError

    typealias AmplifyAuthTaskResult = Result<Success, Failure>

    var value: Success { get async throws }

    var eventName: HubPayloadEventName { get }

    func execute() async throws -> Success

    func dispatch(result: AmplifyAuthTaskResult)

}

public extension AmplifyAuthTaskRefactored {
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

open class AmplifyAuthTask<Request, Success, Failure: AmplifyError> {
    public typealias Success = Success
    public typealias Request = Request
    public typealias Failure = Failure
    public typealias AmplifyAuthTaskResult = Result<Success, Failure>
    
    final public var value: Success {
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

    open func execute() async throws -> Success {
        throw fatalError("Function execute() not implemented")
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
    private func dispatch(result: AmplifyAuthTaskResult) {
        let channel = HubChannel(from: .auth)
        let payload = HubPayload(eventName: eventName, context: nil, data: result)
        Amplify.Hub.dispatch(to: channel, payload: payload)
    }

}
