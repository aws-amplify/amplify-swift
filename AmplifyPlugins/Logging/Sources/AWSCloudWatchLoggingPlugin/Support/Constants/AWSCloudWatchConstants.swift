//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines AWS CloudWatch SDK constants
struct AWSCloudWatchConstants {
    
    /// the max byte size of log events that can be sent is 1 MB
    static let maxBatchByteSize: Int64 = 1_000_000
    
    /// the max number of log events that can be sent is 10,000
    static let maxLogEvents = 10_000
}
