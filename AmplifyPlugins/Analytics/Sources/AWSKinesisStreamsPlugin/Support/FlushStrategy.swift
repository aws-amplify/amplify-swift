//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Strategy for flushing cached records
public enum FlushStrategy: Sendable {
    /// Automatically flush at a regular interval (in seconds). Default is 30 seconds.
    case interval(TimeInterval = 30)
}
