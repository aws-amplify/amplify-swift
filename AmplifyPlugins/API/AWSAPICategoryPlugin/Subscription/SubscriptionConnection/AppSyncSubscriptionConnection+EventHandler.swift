//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AppSyncSubscriptionConnection {

    func onConnectionProviderEvent(event: ConnectionProviderEvent) {
        switch event {
        case .connection(let connectionState):
            handleConnectionState(connectionState: connectionState)
        case .data(let payload):
            handleDataEvent(identifier: identifier, payload: payload)
        case .subscriptionConnected:
            guard let subscriptionItem = subscriptionItems[identifier] else {
                return
            }
            subscriptionItem.setState(.connected)
        case .subscriptionDisconnected:
            guard let subscriptionItem = subscriptionItems[identifier] else {
                return
            }
            subscriptionItem.setState(.disconnected)
            subscriptionItems[subscriptionItem.identifier] = nil
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
            break
        case .disconnected(let error):
            if let error = error {
                tryReconnectOnError(error: error)
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

    // MARK: Error Handling

    func handleSubscriptionError(identifier: String, error: Error) {
        print("Handle Subscription Error \(error)")
        guard let subscriptionItem = subscriptionItems[identifier] else {
            return
        }
        subscriptionItem.setState(.disconnected)
        subscriptionItem.dispatch(error: error)
        subscriptionItems[identifier] = nil
    }

    ///
    func tryReconnectOnError(error: ConnectionProviderError) {
        guard let retryHandler = retryHandler else {
            // dispatch the error on one of the subscriptionItems
            // or all of them?
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
