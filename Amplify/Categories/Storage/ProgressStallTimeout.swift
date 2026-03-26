//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Strategy for cancelling uploads when progress stops advancing.
///
/// Aligns with the pattern used by other Amplify clients (for example flush intervals in the Kinesis client).
/// Configure a default on the S3 storage plugin and optionally override per upload using
/// ``StorageUploadFileRequest/Options`` or ``StorageUploadDataRequest/Options``.
///
/// - Tag: ProgressStallTimeout
public enum ProgressStallTimeout: Sendable, Equatable {
    /// Do not cancel uploads when progress stalls.
    /// Named `disabled` (not `none`) so it does not collide with `Optional.none` when used as `ProgressStallTimeout?`.
    case disabled
    /// Cancel the upload if progress does not advance within this interval (seconds).
    case interval(TimeInterval)
}

public extension ProgressStallTimeout {
    /// Duration in seconds used by the stall timer, or `0` when disabled.
    var secondsForStallTimer: TimeInterval {
        switch self {
        case .disabled:
            return 0
        case .interval(let seconds):
            return max(0, seconds)
        }
    }
}
