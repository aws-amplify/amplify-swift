//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension AppSyncSubscriptionConnection {

    func handleConnectionEvent(identifier: String?, connectionState: ConnectionState) {
        guard let identifier = identifier, let subscriptionItem = subscriptionItems[identifier] else {
            return
        }
        print("Connection state - \(connectionState)")

        switch connectionState {
        case .notConnected:
            if subscriptionItem.subscriptionState == .inProgress {
                // we should retry
                let connectionError = ConnectionProviderError.connection
                handleError(identifier: identifier, error: connectionError)
            }
        case .inProgress:
            subscriptionItem.setState(subscriptionState: .inProgress)
        case .connected:
            print("Start subscription")
            startSubscription(subscriptionItem: subscriptionItem)
        }
    }

    // MARK: -
    private func startSubscription(subscriptionItem: SubscriptionItem) {
        guard subscriptionItem.subscriptionState == .notSubscribed else {
            return
        }

        subscriptionItem.setState(subscriptionState: .inProgress)

        let payload: AppSyncMessage.Payload
        do {
            payload = try convertToPayload(for: subscriptionItem.requestString,
                                               variables: subscriptionItem.variables)
        } catch {
            subscriptionItem.subscriptionEventHandler(.failed(error), subscriptionItem)
            return
        }

        let message = AppSyncMessage(id: subscriptionItem.identifier,
                                     payload: payload,
                                     type: .subscribe("start"))
        connectionProvider.write(message)
    }

    // MARK: -

    private func convertToPayload(for query: String, variables: [String: Any]?) throws -> AppSyncMessage.Payload {
        var dataDict: [String: Any] = ["query": query]
        if let subVariables = variables {
            dataDict["variables"] = subVariables
        }
        var payload = AppSyncMessage.Payload()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dataDict)
            payload.data = String(data: jsonData, encoding: .utf8)
        } catch {
            print(error)
            let jsonError = ConnectionProviderError.jsonParse(nil, error)
            throw jsonError
        }
        return payload
    }

    // MARK: - handle response

    func handleDataEvent(response: AppSyncResponse) {
        guard let identifier = response.id else {
            return
        }

        guard let subscriptionItem = subscriptionItems[identifier] else {
            return
        }

        switch response.responseType {
        case .data:
            do {
                let data = try JSONEncoder().encode(response.payload)
                subscriptionItem.dispatch(data: data)
            } catch {
                print(error)
                let jsonParserError = ConnectionProviderError.jsonParse(response.id, error)
                subscriptionItem.dispatch(error: jsonParserError)
            }
        case .subscriptionAck:
            subscriptionItem.setState(subscriptionState: .subscribed)
        case .unsubscriptionAck:
            subscriptionItem.setState(subscriptionState: .notSubscribed)
        }
    }

    // MARK: handle error

    func handleError(identifier: String?, error: Error) {
        print(error)
        guard let identifier = identifier, let subscriptionItem = subscriptionItems[identifier] else {
            return
        }
        subscriptionItem.setState(subscriptionState: .notSubscribed)
        guard let retryHandler = retryHandler,
            let connectionError = error as? ConnectionProviderError  else {
                subscriptionItem.dispatch(error: error)
                return
        }

        let retryAdvice = retryHandler.shouldRetryRequest(for: connectionError)
        if retryAdvice.shouldRetry, let retryInterval = retryAdvice.retryInterval {
            print("Retrying subscription \(subscriptionItem.identifier) after \(retryInterval)")
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                self.connectionProvider.connect(identifier: subscriptionItem.identifier)
            }

        } else {
            subscriptionItem.dispatch(error: error)
        }
    }
}
