//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Simple pair that represents a category + log level combination.
struct LoggerKey: Hashable {
    var category: String
    var logLevel: LogLevel
}
