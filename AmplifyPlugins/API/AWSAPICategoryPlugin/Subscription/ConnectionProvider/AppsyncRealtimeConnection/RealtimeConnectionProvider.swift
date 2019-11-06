//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Appsync Real time connection that connects to subscriptions
/// through websocket.
class RealtimeConnectionProvider: ConnectionProvider {

    let url: URL
    var status: ConnectionState = .notConnected
    let websocket: AppSyncWebsocketProvider
    var listeners: [ConnectionProviderCallback] = []
    var messageInterceptors: [MessageInterceptor] = []
    var connectionInterceptors: [ConnectionInterceptor] = []

    /// Serial queue for websocket connection.
    ///
    /// Each connection request will be send to this queue. Connection request are handled one at a time.
    let serialConnectionQueue = DispatchQueue(label: "com.amazonaws.AppSyncRealTimeConnectionProvider.serialQueue")

    init(for url: URL, websocket: AppSyncWebsocketProvider) {
        self.url = url
        self.websocket = websocket
    }

    // MARK: - ConnectionProvider methods

    func connect() {
        serialConnectionQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            guard self.status == .notConnected else {
                self.updateCallback(event: .connection(self.status))
                return
            }
            self.status = .inProgress
            self.updateCallback(event: .connection(self.status))
            let request = AppSyncConnectionRequest(url: self.url)
            let signedRequest = self.interceptConnection(request, for: self.url)
            DispatchQueue.global().async {
                self.websocket.connect(url: signedRequest.url,
                                       protocols: ["graphql-ws"],
                                       delegate: self)
            }
        }
    }

    func write(_ message: AppSyncMessage) {
        let signedMessage = interceptMessage(message, for: url)
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(signedMessage)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                updateCallback(event: .error(ConnectionProviderError.jsonParse(message.id, nil)))
                return
            }
            websocket.write(message: jsonString)
        } catch {
            print(error)
            switch message.messageType {
            case .connectionInit:
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }
                    self.status = .notConnected
                    self.updateCallback(event: .error(ConnectionProviderError.connection))
                }
            default:
                updateCallback(event: .error(ConnectionProviderError.jsonParse(message.id, error)))
            }
        }
    }

    func disconnect() {
        websocket.disconnect()
    }

    func addListener(_ callback: @escaping ConnectionProviderCallback) {
        listeners.append(callback)
    }

    // MARK: -
    func sendConnectionInitMessage() {
        let message = AppSyncMessage(type: .connectionInit("connection_init"))
        write(message)
    }

    func updateCallback(event: ConnectionProviderEvent,
                        on queue: DispatchQueue = DispatchQueue.global()) {
        queue.async { [weak self] in
            self?.listeners.forEach { $0(event) }
        }
    }
}
