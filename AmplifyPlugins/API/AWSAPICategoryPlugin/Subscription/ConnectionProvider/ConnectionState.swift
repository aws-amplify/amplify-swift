//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
// Synchronized to the state of the underlying websocket connection
enum ConnectionState {
    // The websocket connection was created
    case connecting

    // The websocket connection has been established
    case connected

    // The websocket connection has been disconnected
    case disconnected(error: ConnectionProviderError?)
}
