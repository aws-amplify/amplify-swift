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
            serialSubscriptionQueue.async {[weak self] in
                self?.subscriptionItems[subscriptionItem.identifier] = nil
            }
        case .keepAlive:
            break
        case .subscriptionError(let identifier, let error):
            handleSubscriptionError(identifier: identifier, error: error)
        case .error(let error):
            Amplify.API.log.error("Connection received error unmappable to any specific subscriber \(error)")
        }

    }

    func handleConnectionState(connectionState: ConnectionState) {
        Amplify.API.log.verbose("Connection state - \(connectionState)")

        switch connectionState {
        case .connecting:
            break
        case .connected:
            serialSubscriptionQueue.async {[weak self] in
                self?.subscriptionItems.forEach { identifier, subscriptionItem in
                    switch subscriptionItem.subscriptionConnectionState {
                    case .disconnected:
                        Amplify.API.log.verbose("Start subscription for identifier: \(subscriptionItem.identifier)")
                        subscriptionItem.setState(.connecting)
                        self?.connectionProvider.subscribe(subscriptionItem)
                    case .connecting, .connected:
                        break
                    }
                }
            }
        case .disconnected(let error):
            if let error = error {
                tryReconnectOnError(error: error)
            }
            serialSubscriptionQueue.async {[weak self] in
                // Move all subscriptionItems to disconnected but keep them in memory.
                self?.subscriptionItems.forEach { _, subscriptionItem in
                    switch subscriptionItem.subscriptionConnectionState {
                    case .connecting, .connected:
                        subscriptionItem.setState(.disconnected)
                    case .disconnected:
                        break
                    }
                }
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
            Amplify.API.log.error(error: error)
            let jsonParserError = ConnectionProviderError.jsonParse(identifier, error)
            subscriptionItem.dispatch(error: APIError.pluginError(jsonParserError))
        }
    }

    // MARK: Error Handling

    func handleSubscriptionError(identifier: String, error: ConnectionProviderError) {
        Amplify.API.log.verbose("Handle Subscription Error \(error)")
        guard let subscriptionItem = subscriptionItems[identifier] else {
            return
        }
        subscriptionItem.setState(.disconnected)
        subscriptionItem.dispatch(error: APIError.pluginError(error))
        subscriptionItems[identifier] = nil
    }

    ///
    func tryReconnectOnError(error: ConnectionProviderError) {
        guard let retryHandler = retryHandler else {
            // TODO: dispatch the error on one of the subscriptionItems or all of them
            Amplify.API.log.warn("[tryReconnectOnError] 1. no retry handler to reconnect on Error \(error)")
            return
        }

        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        if retryAdvice.shouldRetry, let retryInterval = retryAdvice.retryInterval {
            Amplify.API.log.verbose("Retrying websocket connect after retryInterval: \(retryInterval)")
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                self.connectionProvider.connect()
            }
        } else {
            // TODO: dispatch the error on one of the subscriptionItems or all of them
            Amplify.API.log.warn("[tryReconnectOnError] Error \(error)")
        }
    }
}
