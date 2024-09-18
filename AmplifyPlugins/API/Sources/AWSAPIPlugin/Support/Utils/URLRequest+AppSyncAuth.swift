//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

extension URLRequest {
    func injectAppSyncAuthToRequestHeader(auth: AppSyncRealTimeRequestAuth) -> URLRequest {
        var requstCopy = self
        auth.authHeaders.forEach { requstCopy.setValue($0.value, forHTTPHeaderField: $0.key) }
        return requstCopy
    }
}
