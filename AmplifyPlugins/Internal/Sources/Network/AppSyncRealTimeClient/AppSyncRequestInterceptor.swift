//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

@_spi(AppSyncRTC)
public protocol AppSyncRequestInterceptor {
    func interceptRequest(event: AppSyncRealTimeRequest, url: URL) async -> AppSyncRealTimeRequest
}
