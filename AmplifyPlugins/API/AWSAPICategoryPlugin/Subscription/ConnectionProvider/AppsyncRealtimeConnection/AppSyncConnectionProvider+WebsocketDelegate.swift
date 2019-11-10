//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension AppSyncConnectionProvider: WebsocketDelegate {

    func websocketDidConnect(provider: WebsocketProvider) {

        // for all subscriptionItems, call connect.

        // Call the ack to finish the connection handshake
        // Inform the callback when ack gives back a response.
        print("WebsocketDidConnect, sending init message...")
        let message = AppSyncMessage(type: .connectionInit("connection_init"))
        write(message)
    }

    func websocketDidDisconnect(provider: WebsocketProvider, error: Error?) {
        serialConnectionQueue.async {[weak self] in
            guard let self = self else {
                return
            }
            self.status = .notConnected

            guard error == nil else {
                self.listener?(.error(nil, ConnectionProviderError.connection))
                return
            }

            self.listener?(.connection(nil, self.status))
        }
    }

    func websocketDidReceiveData(provider: WebsocketProvider, data: Data) {
        do {
            let response = try JSONDecoder().decode(RealtimeConnectionProviderResponse.self, from: data)
            handleResponse(response)
        } catch {
            print(error)
            listener?(.error(nil, ConnectionProviderError.jsonParse(nil, error)))
        }
    }

    // MARK: - Handle websocket response
    func handleResponse(_ response: RealtimeConnectionProviderResponse) {
        switch response.responseType {
        case .connectionAck:

            /// Only from in progress state, the connection can transiction to connected state.
            /// The below guard statement make sure that. If we get connectionAck in other state means that
            /// we have initiated a disconnect parallely.
            guard status == .inProgress else {
                return
            }
            serialConnectionQueue.async {[weak self] in
                guard let self = self else {
                    return
                }
                self.status = .connected
                self.listener?(.connection(response.id, self.status))
            }
        case .error:
            /// If we get an error in connection inprogress state, return back as connection error.
            if status == .inProgress {
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }
                    self.status = .notConnected
                    self.listener?(.error(response.id, ConnectionProviderError.connection))
                }
                return
            }

            /// Return back as generic error if there is no identifier.
            guard let identifier = response.id else {
                let genericError = ConnectionProviderError.other
                listener?(.error(response.id, genericError))
                return
            }

            /// Map to limit exceed error if we get MaxSubscriptionsReachedException
            if let errorType = response.payload?["errorType"],
                errorType == "MaxSubscriptionsReachedException" {
                let limitExceedError = ConnectionProviderError.limitExceeded(identifier)
                listener?(.error(response.id, limitExceedError))
                return
            }

            let subscriptionError = ConnectionProviderError.subscription(identifier, response.payload)
            listener?(.error(response.id, subscriptionError))
            return

        case .subscriptionAck, .unsubscriptionAck, .data:
            if let appSyncResponse = response.toAppSyncResponse() {
                listener?(.data(appSyncResponse))
            }
        case .keepAlive:
            print("")
        }
    }
}

extension RealtimeConnectionProviderResponse {

    func toAppSyncResponse() -> AppSyncResponse? {
        guard let appSyncType = self.responseType.toAppSyncResponseType() else {
            return nil
        }
        return AppSyncResponse(id: id, payload: payload, type: appSyncType)
    }
}

extension RealtimeConnectionProviderResponseType {

    func toAppSyncResponseType() -> AppSyncResponseType? {
        switch self {
        case .subscriptionAck:
            return .subscriptionAck
        case .unsubscriptionAck:
            return .unsubscriptionAck
        case .data:
            return .data
        default:
            return nil
        }
    }
}
