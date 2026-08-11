//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Simple pair that represents a namespace + log level combination.
struct LoggerKey: Hashable, Sendable {
    var namespace: String
    var logLevel: LogLevel
}
