//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Appsync Real time connection that connects to subscriptions
/// through websocket.
/// Manages the lifecycle of a websocket connection
class AppSyncConnectionProvider: ConnectionProvider {

    let url: URL
    let websocketProvider: WebsocketProvider

    var status: ConnectionState = .disconnected(error: nil)
    var listener: ConnectionProviderCallback?
    var messageInterceptors: [MessageInterceptor] = []

    /// Serial queue for websocket connection.
    ///
    /// Each connection request will be send to this queue. Connection request are handled one at a time.
    let serialConnectionQueue = DispatchQueue(label: "com.amazonaws.AppSyncRealTimeConnectionProvider.serialQueue")

    convenience init(for url: URL, interceptor: AuthInterceptor) {
        let websocketProvider = StarscreamWebsocketProvider(url: url)
        websocketProvider.addInterceptor(AppSyncSubscriptionInterceptor())
        websocketProvider.addInterceptor(interceptor)
        self.init(url: url, websocketProvider: websocketProvider)
    }

    init(url: URL, websocketProvider: WebsocketProvider) {
        self.url = url
        self.websocketProvider = websocketProvider
        websocketProvider.setListener { [weak self] (websocketEvent) in
            guard let self = self else {
                return
            }

            self.onWebsocketEvent(event: websocketEvent)
        }
    }

    // MARK: - ConnectionProvider methods

    /// Connect to the underlying websocket only when no other subscriber has initiated the connection, otherwise
    /// signal the subscriber that it is already connected, in progress, etc.
    func connect() {
        serialConnectionQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            switch self.status {
            case .disconnected:
                DispatchQueue.global().async {
                    self.websocketProvider.connect()
                }
            case .connecting, .connected:
                self.listener?(.connection(self.status))
            }
        }
    }

    func disconnect() {
        websocketProvider.disconnect()
    }

    // Send Connection Init message to ack connection only when is disconnected
    func sendConnectionInitMessage() {
        switch status {
        case .connecting:
            // Call the ack to finish the connection handshake
            // Inform the callback when ack gives back a response.
            print("sendConnectionInitMessage, sending init message...")
            let message = AppSyncMessage(type: .connectionInit("connection_init"))
            do {
                try write(message)
            } catch {
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }
                    let error = ConnectionProviderError.connection(nil)
                    self.status = .disconnected(error: error)
                    self.listener?(.connection(self.status))
                }
            }
        case .disconnected, .connected:
            break
        }
    }

    func sendStartSubscriptionMessage(subscriptionItem: SubscriptionItem) {
        print("sendStartSubscriptionMessage, sending start subscription message...")
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
        do {
            try write(message)
        } catch {
            let error = ConnectionProviderError.jsonParse(message.id, error)
            listener?(.subscriptionError(subscriptionItem.identifier, error))
        }
    }

    func sendUnsubscribeMessage(identifier: String) {
        print("sendStartSubscriptionMessage, sending start subscription message...")
        let message = AppSyncMessage(id: identifier, type: .unsubscribe("stop"))
        do {
            try write(message)
        } catch {
            let error = ConnectionProviderError.jsonParse(message.id, error)
            listener?(.subscriptionError(identifier, error))
        }
    }

    func setListener(_ callback: @escaping ConnectionProviderCallback) {
        listener = callback
    }

    // MARK: - Helpers

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

    private func write(_ message: AppSyncMessage) throws {
        let messageString: String
        do {
            let signedMessage = interceptMessage(message, for: url)
            let jsonData = try JSONEncoder().encode(signedMessage)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                messageString = jsonString
            } else {
                throw ConnectionProviderError.jsonParse(message.id, nil)
            }
            websocketProvider.write(message: messageString)
        } catch {
            throw error
        }
    }
}
