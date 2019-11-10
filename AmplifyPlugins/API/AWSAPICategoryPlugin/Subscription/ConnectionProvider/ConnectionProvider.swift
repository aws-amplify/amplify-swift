//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

protocol ConnectionProvider: class {

    func connect(identifier: String)

    func write(_ message: AppSyncMessage)

    func disconnect()

    func setListener(_ callback: @escaping ConnectionProviderCallback)
}

typealias ConnectionProviderCallback = (ConnectionProviderEvent) -> Void

enum ConnectionProviderEvent {

    case connection(String?, ConnectionState)

    case data(AppSyncResponse)

    case error(String?, Error)
}

/// Connection states
enum ConnectionState {

    case notConnected

    case inProgress

    case connected
}
