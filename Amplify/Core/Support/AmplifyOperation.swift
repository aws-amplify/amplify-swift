//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// An abstract representation of an Amplify unit of work. Subclasses may aggregate multiple work items
/// to fulfull a single "AmplifyOperation", such as an "extract text operation" which might include
/// uploading an image to cloud storage, processing it via a Predictions engine, and translating the results.
///
/// AmplifyOperations are used by plugin developers to perform tasks on behalf of the calling app. They have a default
/// implementation of a `dispatch` method that sends a contextualized payload to the Hub.
///
/// Pausable/resumable tasks that do not require Hub dispatching should use AsynchronousOperation instead.
open class AmplifyOperation<Request: AmplifyOperationRequest, InProcess, Completed,
Error: AmplifyError>: AsynchronousOperation {

    /// The concrete Request associated with this operation
    public typealias Request = Request

    // swiftlint:disable identifier_name
    /// The unique ID of the operation. In categories where operations are persisted for future processing, this id can
    /// be used to identify previously-scheduled work for progress tracking or other functions.
    public let id: UUID
    // swiftlint:enable identifier_name

    /// Incoming parameters of the original request
    public let request: Request

    /// All AmplifyOperations must be associated with an Amplify Category
    public let categoryType: CategoryType

    /// All AmplifyOperations must declare a HubPayloadEventName
    public let eventName: HubPayloadEventName

    private var unsubscribeToken: UnsubscribeToken?

    public init(categoryType: CategoryType,
                eventName: HubPayloadEventName,
                request: Request,
                listener: EventListener? = nil) {
        self.categoryType = categoryType
        self.eventName = eventName
        self.request = request
        id = UUID()

        super.init()

        if let listener = listener {
            unsubscribeToken = subscribe(listener: listener)
        }
    }

    func subscribe(listener: @escaping EventListener) -> UnsubscribeToken {
        let channel = HubChannel(from: categoryType)
        let filterById = HubFilters.hubFilter(forOperation: self)
        let hubListener: HubListener = { payload in
            guard let event = payload.data as? Event else {
                return
            }
            listener(event)
        }
        let token = Amplify.Hub.listen(to: channel, isIncluded: filterById, listener: hubListener)
        return token
    }
}

/// All AmplifyOperations must be associated with an Amplify Category
extension AmplifyOperation: CategoryTypeable { }

/// All AmplifyOperations must declare a HubPayloadEventName. Subclasses should provide names by extending
/// `HubPayload.EventName`, e.g.:
///
/// ```
/// public extension HubPayload.EventName.Storage {
///     static let put = "Storage.put"
/// }
/// ```
extension AmplifyOperation: HubPayloadEventNameable { }

/// Conformance to Cancellable we gain for free by subclassing AsynchronousOperation
extension AmplifyOperation: Cancellable { }

public extension AmplifyOperation {
    /// Convenience typealias defining the AsyncEvents dispatched by this operation
    typealias Event = AsyncEvent<InProcess, Completed, Error>

    /// Convenience typealias for the `listener` callback submitted during Operation creation
    typealias EventListener = (Event) -> Void

    /// Dispatches an event to the hub. Internally, creates an `AmplifyOperationContext` object from the
    /// operation's `id`, and `request`
    /// - Parameter event: The AsyncEvent to dispatch to the hub as part of the HubPayload
    func dispatch(event: Event) {
        let channel = HubChannel(from: categoryType)
        let context = AmplifyOperationContext(operationId: id, request: request)
        let payload = HubPayload(eventName: eventName, context: context, data: event)
        Amplify.Hub.dispatch(to: channel, payload: payload)
    }

    /// Removes the listener that was registered during operation instantiation
    func removeListener() {
        guard let unsubscribeToken = unsubscribeToken else {
            return
        }
        Amplify.Hub.removeListener(unsubscribeToken)
    }

}

/// Describes the parameters that are passed during the creation of an AmplifyOperation
public protocol AmplifyOperationRequest {
    /// The concrete Options type that adjusts the behavior of the request type
    associatedtype Options

    /// Options to adjust the behavior of this request, including plugin options
    var options: Options { get }
}

public extension HubCategory {

    /// Convenience method to allow callers to listen to Hub events for a particular operation. Internally, the listener
    /// transforms the HubPayload into the Operation's expected AsyncEvent type, so callers may re-use their `listener`s
    ///
    /// - Parameter operation: The operation to listen to events for
    /// - Parameter listener: The Operation-specific listener callback to be invoked when an AsyncEvent for that
    ///   operation is received.
    func listen<Request: AmplifyOperationRequest,
        InProcess,
        Completed,
        Error: AmplifyError>(to operation: AmplifyOperation<Request, InProcess, Completed, Error>,
                             listener: @escaping AmplifyOperation<Request, InProcess, Completed, Error>.EventListener)
        -> UnsubscribeToken {
            let channel = HubChannel(from: operation.categoryType)
            let filter = HubFilters.hubFilter(forOperation: operation)
            let transformingListener: HubListener = { payload in
                guard let data = payload.data as? AmplifyOperation<Request, InProcess, Completed, Error>.Event else {
                    return
                }
                listener(data)
            }
            let token = listen(to: channel, isIncluded: filter, listener: transformingListener)
            return token
    }
}
