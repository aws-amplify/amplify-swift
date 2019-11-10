//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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
