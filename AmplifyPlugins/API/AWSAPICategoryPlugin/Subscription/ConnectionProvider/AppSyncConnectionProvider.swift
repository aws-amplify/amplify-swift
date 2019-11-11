//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Appsync Real time connection that connects to subscriptions
/// through websocket.
/// Manages the lifecycle of a websocket connection
class AppSyncConnectionProvider: ConnectionProvider {

    let url: URL
    let websocketProvider: WebsocketProvider

    var state: ConnectionState = .disconnected(error: nil)

    var listeners: [String: ConnectionProviderCallback] = [:]
    var messageInterceptors: [MessageInterceptor] = []

    /// Serial queue for maintaining the connection state in sync with the websocket connection
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

    /// Begins websocket handshake if it is disconnected.
    /// Signals listener when already connected or connecting
    func connect() {
        switch state {
        case .disconnected:
            websocketProvider.connect()
        case .connecting, .connected:
            dispatch(.connection(state))
        }
    }

    /// Begins websocket disconnect if it is connected or connecting.
    /// Signals listener if it is disconnected already.
    func disconnect() {
        switch state {
        case .connecting, .connected:
            websocketProvider.disconnect()
        case .disconnected:
            dispatch(.connection(state))
        }
    }

    func subscribe(_ identifier: String,
                   requestString: String,
                   variables: [String: Any]?) {
        print("subscribe, sending start subscription message...")
        let payload: AppSyncMessage.Payload
        do {
            payload = try convertToPayload(for: requestString,
                                           variables: variables)
        } catch {
            let error = ConnectionProviderError.jsonParse(identifier, error)
            dispatch(identifier, event: .subscriptionError(identifier, error))
            return
        }

        let message = AppSyncMessage(id: identifier,
                                     payload: payload,
                                     type: .subscribe("start"))
        do {
            try write(message)
        } catch {
            let error = ConnectionProviderError.jsonParse(message.id, error)
            dispatch(identifier, event: .subscriptionError(identifier, error))
        }
    }

    func unsubscribe(_ identifier: String) {
        print("sendStartSubscriptionMessage, sending start subscription message...")
        let message = AppSyncMessage(id: identifier, type: .unsubscribe("stop"))
        do {
            try write(message)
        } catch {
            let error = ConnectionProviderError.jsonParse(message.id, error)
            dispatch(identifier, event: .subscriptionError(identifier, error))
        }
    }

    var isConnected: Bool {
        if case .connected = state {
            return true
        }

        return false
    }

    func addListener(_ identifier: String, callback: @escaping ConnectionProviderCallback) {
        listeners[identifier] = callback
    }

    func removeListener(_ identifier: String) {
        listeners[identifier] = nil
    }

    // MARK: - Helpers

    func dispatch(_ event: ConnectionProviderEvent) {
        listeners.forEach { (_, callback) in
            callback(event)
        }
    }

    func dispatch(_ identifier: String, event: ConnectionProviderEvent) {
        if let callback = listeners[identifier] {
            callback(event)
        }
    }

    // MARK: - Private

    /// Send Connection Init message to finish the connection handshake
    func sendConnectionInitMessage() {
        switch state {
        case .connecting:
            print("sendConnectionInitMessage, sending init message...")
            let message = AppSyncMessage(type: .connectionInit("connection_init"))
            do {
                try write(message)
            } catch {
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }
                    self.state = .disconnected(error: ConnectionProviderError.connection(nil))
                    self.dispatch(.connection(self.state))
                }
            }
        case .disconnected, .connected:
            break
        }
    }

    private func write(_ appSyncMessage: AppSyncMessage) throws {
        do {
            let message = try encode(appSyncMessage: appSyncMessage)
            websocketProvider.write(message)
        } catch {
            throw error
        }
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

    private func encode(appSyncMessage: AppSyncMessage) throws -> String {
        do {
            let signedMessage = interceptMessage(appSyncMessage, for: url)
            let jsonData = try JSONEncoder().encode(signedMessage)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw ConnectionProviderError.jsonParse(appSyncMessage.id, nil)
            }
            return jsonString
        } catch {
            throw ConnectionProviderError.jsonParse(appSyncMessage.id, error)
        }
    }
}
