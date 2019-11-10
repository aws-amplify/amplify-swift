//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

struct SubscriptionConstants {
    static let appsyncHostPart = "appsync-api"

    static let appsyncRealtimeHostPart = "appsync-realtime-api"

    static let realtimeWebsocketScheme = "wss"

    static let emptyPayload = "{}"

    static let appsyncServiceName = "appsync"

    static let authorizationkey = "Authorization"
}

struct RealtimeProviderConstants {

    static let header = "header"

    static let payload = "payload"

    static let amzDate = "x-amz-date"

    static let iamAccept = "application/json, text/javascript"

    static let iamEncoding = "amz-1.0"

    static let iamConentType = "application/json; charset=UTF-8"

    static let iamConnectPath = "connect"

    static let iamSecurityTokenKey = "X-Amz-Security-Token"

    static let acceptKey = "accept"

    static let contentTypeKey = "content-type"

    static let contentEncodingKey = "content-encoding"
}
