//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol ConnectionProvider: class {

    func connect()

    func write(_ message: AppSyncMessage)

    func disconnect()

    func addListener(identifier: String, callback: @escaping ConnectionProviderCallback)

    func removeListener(identifier: String)
}

public typealias ConnectionProviderCallback = (ConnectionProviderEvent) -> Void

public enum ConnectionProviderEvent {

    case connection(ConnectionState)

    case data(AppSyncResponse)

    case error(Error)
}

/// Connection states
public enum ConnectionState {

    case notConnected

    case inProgress

    case connected
}
