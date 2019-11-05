//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct URLRequestContants {
    static let appSyncServiceName = "appsync"

    struct Header {
        static let xAmzDate = "X-Amz-Date"
        static let contentType = "Content-Type"
        static let userAgent = "User-Agent"
        static let xApiKey = "x-api-key"
    }

    struct ContentType {
        static let applicationJson = "application/json"
    }

    struct UserAgent {
        static let amplify = "amplify-ios/0.0.1 Amplify"
    }
}
