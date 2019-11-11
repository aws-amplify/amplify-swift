//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import Amplify

extension AppSyncSubscriptionConnection {

    func onConnectionProviderEvent(event: ConnectionProviderEvent) {
        switch event {
        case .connection(let connectionState):
            handleConnectionState(connectionState: connectionState)
        case .data(let identifier, let payload):
            handleDataEvent(identifier: identifier, payload: payload)
        case .subscriptionConnected(let identifier):
            guard let subscriptionItem = subscriptionItems[identifier] else {
                return
            }
            subscriptionItem.setState(.connected)
        case .subscriptionDisconnected(let identifier):
            guard let subscriptionItem = subscriptionItems[identifier] else {
                return
            }
            subscriptionItem.setState(.disconnected)
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
            // Transition any subscribers to inProgress if they are not subscribed.
            subscriptionItems.forEach { (identifier, subscriptionItem) in
                if subscriptionItem.subscriptionConnectionState == .disconnected {
                    subscriptionItem.setState(.connecting)
                }
            }
            connectionProvider.sendConnectionInitMessage()
        case .connected:
            // Connection is ready so start the subscription for any not connected subscribers
            subscriptionItems.forEach { (identifier, subscriptionItem) in
                switch subscriptionItem.subscriptionConnectionState  {
                case .disconnected, .connecting:
                    print("Start subscription for identifier: \(subscriptionItem.identifier)")
                    connectionProvider.sendStartSubscriptionMessage(subscriptionItem: subscriptionItem)
                case .connected:
                    break
                }
            }
        case .disconnected(let error):
            // what do we do when we see a disconnected
            subscriptionItems.forEach { (identifier, subscriptionItem) in
                switch subscriptionItem.subscriptionConnectionState {
                case .connecting, .connected:
                    // Do we have to send unsubscribe message or just set state?
                    subscriptionItem.setState(.disconnected)
                    // connectionProvider.sendUnsubscribeMessage(identifier: identifier)
                case .disconnected:
                    break
                }
            }

            // if there is an error and has not exhausted all retry (TODO), then try to disconnect
            if let error = error {
                // try reconnecting
                handleConnectionError(error: error)
                // if all fails, then inform the subscriptions to disconnect
            }

        }
    }

    // MARK: - handle response

    func handleDataEvent(identifier: String, payload: [String: JSONValue]) {
        guard let subscriptionItem = subscriptionItems[identifier] else {
            return
        }

        do {
            let data = try JSONEncoder().encode(payload)
            subscriptionItem.dispatch(data: data)
        } catch {
            print(error)
            let jsonParserError = ConnectionProviderError.jsonParse(identifier, error)
            subscriptionItem.dispatch(error: jsonParserError)
        }
    }

    // MARK: handle error

    func handleSubscriptionError(identifier: String, error: Error) {
        print("Handle Subscription Error \(error)")
        guard let subscriptionItem = subscriptionItems[identifier] else {
            return
        }
        subscriptionItem.setState(.disconnected)
        subscriptionItem.dispatch(error: error)
    }

    func handleConnectionError(error: ConnectionProviderError) {
        guard let retryHandler = retryHandler else {
            // no retry handler, just dispatch the error to who?
            print("1.no retry handler, dispatch to who?")
            return
        }

        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        if retryAdvice.shouldRetry, let retryInterval = retryAdvice.retryInterval {
            // print("Retrying subscription \(subscriptionItem.identifier) after \(retryInterval)")
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                self.connectionProvider.connect()
            }
        } else {
            // just dispatch error to who?
            print("2.no retry handler, dispatch to who?")
        }
    }
}
