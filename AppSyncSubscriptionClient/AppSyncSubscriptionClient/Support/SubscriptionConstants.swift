//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SubscriptionConstants {
    public static let appsyncHostPart = "appsync-api"

    public static let appsyncRealtimeHostPart = "appsync-realtime-api"

    public static let realtimeWebsocketScheme = "wss"

    public static let emptyPayload = "{}"

    public static let appsyncServiceName = "appsync"

    public static let authorizationkey = "Authorization"
}

public struct RealtimeProviderConstants {

    public static let header = "header"

    public static let payload = "payload"

    public static let amzDate = "x-amz-date"

    public static let iamAccept = "application/json, text/javascript"

    public static let iamEncoding = "amz-1.0"

    public static let iamConentType = "application/json; charset=UTF-8"

    public static let iamConnectPath = "connect"

    public static let iamSecurityTokenKey = "X-Amz-Security-Token"

    public static let acceptKey = "accept"

    public static let contentTypeKey = "content-type"

    public static let contentEncodingKey = "content-encoding"
}
