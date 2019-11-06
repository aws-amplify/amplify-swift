//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension AppSyncSubscriptionConnection {

    func handleConnectionEvent(connectionState: ConnectionState) {
        print("Connection state - \(connectionState)")

        // If we get back not connected during an inprogress subscription connection
        // we should retry the connection
        if connectionState == .notConnected
            && subscriptionState == .inProgress {
            let connectionError = ConnectionProviderError.connection
            handleError(error: connectionError)
            return
        }
        if connectionState == .connected {
            print("Start subscription")
            startSubscription()
        }
    }

    // MARK: -
    private func startSubscription() {
        guard subscriptionState == .notSubscribed else {
            return
        }
        subscriptionState = .inProgress
        let payload = convertToPayload(for: subscriptionItem.requestString, variables: subscriptionItem.variables)
        let message = AppSyncMessage(id: subscriptionItem.identifier,
                                     payload: payload,
                                     type: .subscribe("start"))
        connectionProvider?.write(message)
    }

    private func convertToPayload(for query: String, variables: [String: Any]?) -> AppSyncMessage.Payload {
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
            subscriptionItem.subscriptionEventHandler(.failed(jsonError), subscriptionItem)
        }
        return payload
    }
}
