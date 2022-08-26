//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AWSCognitoNetworkPreferences {
    
    /// The timeout interval to use when waiting for additional data.
    public let maxRetryCount: UInt32
    
    /// The timeout interval to use when waiting for additional data.
    public let timeoutIntervalForRequest: Double
    
    /// The maximum amount of time that a resource request should be allowed to take.
    public let timeoutIntervalForResource: Double
    
    public init(maxRetryCount: UInt32,
                timeoutIntervalForRequest: Double,
                timeoutIntervalForResource: Double) {
        self.maxRetryCount = maxRetryCount
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.timeoutIntervalForResource = timeoutIntervalForResource
    }
}
