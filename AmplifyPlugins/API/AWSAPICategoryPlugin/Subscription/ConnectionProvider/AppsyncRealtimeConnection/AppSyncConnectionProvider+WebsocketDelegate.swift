//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension AppSyncConnectionProvider {

    // MARK: - Handle websocket response
    func handleResponse(_ response: WebsocketProviderResponse) {
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
                self.listener?(.connection(self.status))
            }
        case .error:
            /// If we get an error in connection inprogress state, return back as connection error.
            if status == .inProgress {
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }
                    self.status = .notConnected
                    self.listener?(.error(response.identifier, ConnectionProviderError.connection))
                }
                return
            }

            /// Return back as generic error if there is no identifier.
            guard let identifier = response.identifier else {
                let genericError = ConnectionProviderError.other
                listener?(.error(response.identifier, genericError))
                return
            }

            /// Map to limit exceed error if we get MaxSubscriptionsReachedException
            if let errorType = response.payload?["errorType"],
                errorType == "MaxSubscriptionsReachedException" {
                let limitExceedError = ConnectionProviderError.limitExceeded(identifier)
                listener?(.error(response.identifier, limitExceedError))
                return
            }

            let subscriptionError = ConnectionProviderError.subscription(identifier, response.payload)
            listener?(.error(response.identifier, subscriptionError))
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

extension WebsocketProviderResponse {

    func toAppSyncResponse() -> AppSyncResponse? {
        guard let appSyncType = self.responseType.toAppSyncResponseType() else {
            return nil
        }
        return AppSyncResponse(id: identifier, payload: payload, type: appSyncType)
    }
}

extension WebsocketProviderResponseType {

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
