//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AWSCognitoNetworkPreferences {

    /// The maximum number of retries for failed requests.
    public let maxRetryCount: UInt32

    /// The timeout interval to use when waiting for additional data.
    public let timeoutIntervalForRequest: TimeInterval

    /// The maximum amount of time that a resource request should be allowed to take.
    /// 
    /// NOTE: This value is only applicable to HostedUI because the underlying Swift SDK does
    /// not support resource timeouts
    public let timeoutIntervalForResource: TimeInterval?

    public init(maxRetryCount: UInt32,
                timeoutIntervalForRequest: TimeInterval,
                timeoutIntervalForResource: TimeInterval? = nil) {
        self.maxRetryCount = maxRetryCount
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.timeoutIntervalForResource = timeoutIntervalForResource
    }
}
