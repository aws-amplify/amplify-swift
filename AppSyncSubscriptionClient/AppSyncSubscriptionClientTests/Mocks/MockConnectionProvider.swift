//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AppSyncSubscriptionClient

class MockConnectionProvider: ConnectionProvider {

    /// If this boolean is set, all the request to this provider will return a connection error
    let validConnection: Bool

    /// If this boolean is set, all the request to this provider will return `notConnected` event
    var isConnected: Bool = true

    init (validConnection: Bool = true) {
        self.validConnection = validConnection
    }

    var listener: ConnectionProviderCallback?

    func connect() {
        guard validConnection else {
            listener?(.error(ConnectionProviderError.connection))
            return
        }

        guard isConnected else {
            listener?(.connection(.notConnected))
            return
        }

        listener?(.connection(.connected))
    }

    func write(_ message: AppSyncMessage) {

        guard validConnection else {
            listener?(.error(ConnectionProviderError.connection))
            return
        }

        guard isConnected else {
            listener?(.connection(.notConnected))
            return
        }

        switch message.messageType {
        case .connectionInit:
            print("")
        case .subscribe:
            let response = AppSyncResponse(id: message.id,
                                           payload: [:],
                                           type: .subscriptionAck)
            listener?(.data(response))
        case .unsubscribe:
            let response = AppSyncResponse(id: message.id,
                                           payload: [:],
                                           type: .unsubscriptionAck)
            listener?(.data(response))
        }
    }

    func disconnect() {
        guard validConnection else {
            listener?(.error(ConnectionProviderError.connection))
            return
        }

        guard isConnected else {
            listener?(.connection(.notConnected))
            return
        }

        listener?(.connection(.notConnected))
    }

    func addListener(identifier: String, callback: @escaping ConnectionProviderCallback) {
        listener = callback
    }

    func removeListener(identifier: String) {
        listener = nil
    }
    func sendDataResponse(_ response: AppSyncResponse) {
        listener?(.data(response))
    }
}

class MockConnectionProviderAlwaysConnect: MockConnectionProvider {

    override func connect() {
        listener?(.connection(.connected))
    }

}
