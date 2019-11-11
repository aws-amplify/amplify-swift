//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

enum ConnectionProviderEvent {

    case connection(ConnectionState)

    // Keep alive ping from the service
    case keepAlive

    // Subscription has been connected to the connection
    case subscriptionConnected

    // Subscription has been disconnected from the connection
    case subscriptionDisconnected

    // Data received on the connection
    case data(payload: [String: JSONValue])

    // Subscription related error
    case subscriptionError(String, ConnectionProviderError)

    // Unknown error
    case unknownError(ConnectionProviderError)
}
