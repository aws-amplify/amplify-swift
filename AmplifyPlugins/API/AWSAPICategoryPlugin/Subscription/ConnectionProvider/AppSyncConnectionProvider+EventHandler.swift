//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AppSyncConnectionProvider {

    // MARK: - Handle websocket response

    func onWebsocketEvent(event: WebsocketEvent) {
        switch event {
        case .connect:
            serialConnectionQueue.async { [weak self] in
                guard let self = self else {
                    return
                }

                self.state = .connecting
                self.dispatch(.connection(.connecting))

                // Connection provider will internally send connection init message.
                self.sendConnectionInitMessage()
                // TODO: Fire off a timer here to mark the beginning of connecting.
                // When timer fires, and connecting never moves to connected
                // then call sendConnectionInitMessage() to resend it.
            }
        case .disconnect(let error):
            serialConnectionQueue.async {[weak self] in
                guard let self = self else {
                    return
                }

                if let error = error {
                    let connectionProviderError = ConnectionProviderError.connection(error)
                    self.state = .disconnected(error: connectionProviderError)
                } else {
                    self.state = .disconnected(error: nil)
                }
                self.dispatch(.connection(self.state))
            }
        case .data(let websocketResponse):
            handleResponse(websocketResponse)
        case .error(let error):
            print("Got error bac")
        }
    }

    // MARK: - Helpers

    func handleResponse(_ response: WebsocketProviderResponse) {
        switch response.responseType {
        case .connectionAck:
            switch state {
                case .connecting:
                    serialConnectionQueue.async {[weak self] in
                        guard let self = self else {
                            return
                        }

                        self.state = .connected
                        self.dispatch(.connection(self.state))
                    }
                case .connected, .disconnected:
                    break
            }

        case .error:
            switch state {
            case .connecting:
                /// If we get an error while trying to connect, return it back as connection error.
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }

                    // TODO: Deserialize payload here to get error?
                    self.state = .disconnected(error: ConnectionProviderError.responseError)
                    self.dispatch(.connection(self.state))
                }
                return
            case .connected, .disconnected:
                break
            }

            /// Return back as generic error if there is no identifier.
            guard let identifier = response.identifier else {
                let genericError = ConnectionProviderError.other
                dispatch(.unknownError(genericError))
                return
            }

            /// Map to limit exceed error if we get MaxSubscriptionsReachedException
            if let errorType = response.payload?["errorType"],
                errorType == "MaxSubscriptionsReachedException" {
                let limitExceedError = ConnectionProviderError.limitExceeded(identifier)
                dispatch(identifier, event: .subscriptionError(identifier, limitExceedError))
                return
            }

            // Default to subscription error
            let subscriptionError = ConnectionProviderError.subscription(identifier, response.payload)
            dispatch(identifier, event: .subscriptionError(identifier, subscriptionError))
            return

        case .subscriptionAck:
            if let identifier = response.identifier {
                dispatch(identifier, event: .subscriptionConnected)
            }
        case .unsubscriptionAck:
            if let identifier = response.identifier {
                dispatch(identifier, event: .subscriptionDisconnected)
            }
        case .data:
            if let identifier = response.identifier, let payload = response.payload {
                dispatch(identifier, event: .data(payload: payload))
            }
        case .keepAlive:
            dispatch(.keepAlive)
        }
    }
}
