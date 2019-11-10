//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Appsync Real time connection that connects to subscriptions
/// through websocket.
class AppSyncConnectionProvider: ConnectionProvider {

    let url: URL
    let websocketProvider: WebsocketProvider

    var status: ConnectionState = .notConnected
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
    }

    // MARK: - ConnectionProvider methods

    func connect(identifier: String) {
        serialConnectionQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            if self.status == .notConnected {
                self.status = .inProgress

                DispatchQueue.global().async {
                    self.websocketProvider.connect()
                }
            }

            self.listener?(.connection(identifier, self.status))
        }
    }

    func write(_ message: AppSyncMessage) {
        let signedMessage = interceptMessage(message, for: url)
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(signedMessage)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                let error = ConnectionProviderError.jsonParse(message.id, nil)
                listener?(.error(message.id, error))
                return
            }
            websocketProvider.write(message: jsonString)
        } catch {
            print(error)
            switch message.messageType {
            case .connectionInit:
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }
                    self.status = .notConnected
                    self.listener?(.error(message.id, ConnectionProviderError.connection))
                }
            default:
                let error = ConnectionProviderError.jsonParse(message.id, error)
                listener?(.error(message.id, error))
            }
        }
    }

    func disconnect() {
        websocketProvider.disconnect()
    }

    func setListener(_ callback: @escaping ConnectionProviderCallback) {
        listener = callback
    }
}
