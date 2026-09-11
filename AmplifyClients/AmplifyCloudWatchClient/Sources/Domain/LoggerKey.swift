//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Identifies a logging session controller by namespace. Log level is per-message data
/// (filtered by `CloudWatchLoggingFilter`), not per-stream state, so it is not part of the key —
/// otherwise each level under one namespace would get its own controller writing the same files.
struct LoggerKey: Hashable, Sendable {
    var namespace: String
}
