//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Struct to hold the connection url and protocols
struct AppSyncConnectionRequest {

    /// url to connect
    let url: URL

    init(url: URL) {
        self.url = url
    }
}
