//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// TODO: remove this https://github.com/aws-amplify/amplify-ios/issues/75
struct URLRequestConstants {
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
}
