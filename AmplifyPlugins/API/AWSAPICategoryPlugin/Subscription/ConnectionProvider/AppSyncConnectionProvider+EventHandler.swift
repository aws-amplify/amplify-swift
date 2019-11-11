//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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

                self.status = .connecting
                self.listener?(.connection(.connecting))
            }
        case .disconnect(let error):
            serialConnectionQueue.async {[weak self] in
                guard let self = self else {
                    return
                }

                if let error = error {
                    let connectionProviderError = ConnectionProviderError.connection(error)
                    self.status = .disconnected(error: connectionProviderError)
                } else {
                    self.status = .disconnected(error: nil)
                }
                self.listener?(.connection(self.status))
            }
        case .data(let websocketResponse):
            handleResponse(websocketResponse)
        }
    }

    // MARK: - Helpers

    func handleResponse(_ response: WebsocketProviderResponse) {
        switch response.responseType {
        case .connectionAck:

            serialConnectionQueue.async {[weak self] in
                guard let self = self else {
                    return
                }

                // Only transition to `connected` from `connecting`, otherwise disconnect was trigger in parallel
                switch self.status {
                case .connecting:
                    self.status = .connected
                    self.listener?(.connection(self.status))
                case .connected, .disconnected:
                    break
                }

            }
        case .error:
            switch status {
            case .connecting:
                /// If we get an error while trying to connect, return it back as connection error.
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }

                    // TODO: Deserialize payload here to get error?
                    self.status = .disconnected(error: ConnectionProviderError.responseError)
                    self.listener?(.connection(self.status))
                }
                return
            case .connected, .disconnected:
                break
            }

            /// Return back as generic error if there is no identifier.
            guard let identifier = response.identifier else {
                let genericError = ConnectionProviderError.other
                listener?(.unknownError(genericError))
                return
            }

            /// Map to limit exceed error if we get MaxSubscriptionsReachedException
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
