//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Result of flushing records
public struct FlushData: Sendable {
    public let recordsFlushed: Int
}

/// Result of clearing cache
public struct ClearCacheData: Sendable {
    public let recordsCleared: Int
}
