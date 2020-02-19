//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Struct to hold the connection url and protocols
public struct AppSyncConnectionRequest {

    /// url to connect
    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}
