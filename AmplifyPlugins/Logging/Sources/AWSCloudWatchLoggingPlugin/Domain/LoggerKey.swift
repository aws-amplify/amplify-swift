//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Identifies a logging session controller by category, the directory its logs live in. Log level isn't
/// part of the key: `AWSCloudWatchLoggingFilter` filters each message, and a controller per level would
/// write the same files.
struct LoggerKey: Hashable {
    var category: String
}
