//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AppSyncRequestInterceptor: Sendable {
    func interceptRequest(event: AppSyncRealTimeRequest, url: URL) async -> AppSyncRealTimeRequest
}
