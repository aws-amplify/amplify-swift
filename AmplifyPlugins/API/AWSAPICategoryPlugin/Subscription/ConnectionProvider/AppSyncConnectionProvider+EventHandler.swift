//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AppSyncConnectionProvider {

    func onWebsocketEvent(event: WebsocketEvent) {
        switch event {
        case .connect:
            serialConnectionQueue.async { [weak self] in
                guard let self = self else {
                    return
                }

                self.state = .connecting
                self.listener?(.connection(.connecting))
                self.sendConnectionInitMessage()
                self.disconnectIfStale()
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
                self.listener?(.connection(self.state))
            }
        case .data(let websocketResponse):
            handleResponse(websocketResponse)
        case .error(let error):
            Amplify.API.log.error("Websocket Error: \(error)")
        }
    }

    // MARK: - Helpers

    func handleResponse(_ response: WebsocketProviderResponse) {
        lastKeepAliveTime = DispatchTime.now()

        switch response.responseType {
        case .connectionAck:
            switch state {
                case .connecting:
                    serialConnectionQueue.async {[weak self] in
                        guard let self = self else {
                            return
                        }

                        self.state = .connected
                        self.listener?(.connection(self.state))
                    }
                case .connected, .disconnected:
                    Amplify.API.log.verbose(
                        "[AppSyncConnectionProvider] connectionAck recieved while connection is \(state)")
            }

        case .error:
            switch state {
            case .connecting:
                // If we get an error while trying to connect, return it back as connection error.
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }

                    // TODO: Deserialize payload here to get error?
                    self.state = .disconnected(error: ConnectionProviderError.responseError)
                    self.listener?(.connection(self.state))
                }
                return
            case .connected, .disconnected:
                break
            }

            guard let identifier = response.identifier else {
                let error = ConnectionProviderError.unknown(
                    "Response contained error without subscription identifier")
                listener?(.error(error))
                return
            }

            // Map to limit exceed error if we get MaxSubscriptionsReachedException
            if let errorType = response.payload?["errorType"],
                errorType == "MaxSubscriptionsReachedException" {
                let limitExceedError = ConnectionProviderError.limitExceeded(identifier)
                listener?(.subscriptionError(identifier, limitExceedError))
                return
            }

            // Default to subscription error
            let subscriptionError = ConnectionProviderError.subscription(identifier, response.payload)
            listener?(.subscriptionError(identifier, subscriptionError))
            return

        case .subscriptionAck:
            if let identifier = response.identifier {
                listener?(.subscriptionConnected(identifier: identifier))
            }
        case .unsubscriptionAck:
            if let identifier = response.identifier {
                listener?(.subscriptionDisconnected(identifier: identifier))
            }
        case .data:
            if let identifier = response.identifier, let payload = response.payload {
                listener?(.data(identifier: identifier, payload: payload))
            }
        case .keepAlive:
            listener?(.keepAlive)
        }
    }
}
