//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Event handler for subscription.
typealias SubscriptionEventHandler<T> = (SubscriptionEvent<T>, SubscriptionItem) -> Void


/// Item that holds the subscription. This contains the raw query and variables.
class SubscriptionItem {

    /// Identifier for the subscription
    let identifier: String

    /// Subscription variables for the query
    let variables: [String: Any]?

    /// Request query for subscription
    let requestString: String

    /// State of the subscription
    var subscriptionConnectionState: SubscriptionConnectionState

    // Subscription related aevents will be send to this handler.
    let subscriptionEventHandler: SubscriptionEventHandler<Data>

    init(requestString: String,
         variables: [String: Any]?,
         subscriptionConnectionState: SubscriptionConnectionState = .disconnected,
         eventHandler: @escaping SubscriptionEventHandler<Data>) {

        self.identifier = UUID().uuidString
        self.variables = variables
        self.requestString = requestString
        self.subscriptionConnectionState = subscriptionConnectionState
        self.subscriptionEventHandler = eventHandler
    }

    func setState(_ subscriptionConnectionState: SubscriptionConnectionState) {
        self.subscriptionConnectionState = subscriptionConnectionState
        subscriptionEventHandler(.connection(self.subscriptionConnectionState), self)
    }

    func dispatch(data: Data) {
        subscriptionEventHandler(.data(data), self)
    }

    func dispatch(error: Error) {
        subscriptionEventHandler(.failed(error), self)
    }
}

typealias SubscriptionEventListener<R: Decodable> = (SubscriptionEvent<R>) -> Void

class SubscriptionOperation<R: Decodable>: AsynchronousOperation {
    let identifier = UUID().uuidString
    let request: GraphQLRequest
    let responseType: R.Type
    let connectionProvider: ConnectionProvider
    let listener: SubscriptionEventListener<R>

    /// State of the subscription // TODO: Maybe a didSet
    var subscriptionConnectionState: SubscriptionConnectionState = .disconnected

    init(request: GraphQLRequest,
         responseType: R.Type,
         connectionProvider: ConnectionProvider,
         listener: @escaping SubscriptionEventListener<R>) {
        self.request = request
        self.responseType = responseType
        self.connectionProvider = connectionProvider
        self.listener = listener

        self.connectionProvider.addListener(identifier) { [weak self] (event) in
            guard let self = self else {
                return
            }

            self.onConnectionProviderEvent(event: event)
        }
    }

    override public func cancel() {
        connectionProvider.unsubscribe(identifier)
        super.cancel()
    }

    override func main() {
        if isCancelled {
            finish()
        }

        // TODO: validate payload.

        if connectionProvider.isConnected {
            connectionProvider.subscribe(identifier,
                                         requestString: request.document,
                                         variables: request.variables)
        } else {
            connectionProvider.connect()
        }
    }

    func onConnectionProviderEvent(event: ConnectionProviderEvent) {
        switch event {
        case .connection(let connectionState):
            handleConnectionState(connectionState: connectionState)
        case .data(let payload):
            handleDataEvent(payload: payload)
        case .subscriptionConnected:
            subscriptionConnectionState = .connected
            listener(.connection(subscriptionConnectionState))
        case .subscriptionDisconnected:
            subscriptionConnectionState = .disconnected
            listener(.connection(subscriptionConnectionState))
            connectionProvider.removeListener(identifier)
            finish()
        case .keepAlive:
            break
        case .subscriptionError(let identifier, let error):
            handleSubscriptionError(identifier: identifier, error: error)
        case .unknownError(let error):
            break
        }

    }

    func handleConnectionState(connectionState: ConnectionState) {
        print("Connection state - \(connectionState)")

        switch connectionState {
        case .connecting:
            break
        case .connected:
            switch subscriptionConnectionState {
            case .disconnected:
                print("Start subscription for identifier: \(identifier)")
                subscriptionConnectionState = .connecting
                listener(.connection(subscriptionConnectionState))
                connectionProvider.subscribe(identifier,
                                             requestString: request.document,
                                             variables: request.variables)
            case .connecting, .connected:
                break
            }
        case .disconnected:
            switch subscriptionConnectionState {
            case .connecting, .connected:
                subscriptionConnectionState = .disconnected
                listener(.connection(subscriptionConnectionState))
            case .disconnected:
                break
            }
        }
    }

    // MARK: - handle response

    func handleDataEvent(payload: [String: JSONValue]) {
        do {
            let graphQLResponseData = try JSONEncoder().encode(payload)
            let graphQLServiceResponse = try GraphQLResponseDecoder.deserialize(graphQLResponse: graphQLResponseData)
            let graphQLResponse = try GraphQLResponseDecoder.decode(graphQLServiceResponse: graphQLServiceResponse,
                                                                    responseType: responseType)
            let event = SubscriptionEvent<GraphQLResponse<R>>.data(graphQLResponse)
            listener(event)


        } catch {
            print(error)
            let jsonParserError = ConnectionProviderError.jsonParse(identifier, error)
            listener(.failed(jsonParserError))
        }
    }

    // MARK: Error Handling

    func handleSubscriptionError(identifier: String, error: Error) {
        print("Handle Subscription Error \(error)")
        subscriptionConnectionState = .disconnected
        listener(.connection(subscriptionConnectionState))
        listener(.failed(error))
        finish()
    }

    ///

}



