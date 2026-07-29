//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that abstracts a log entry for use in shared logging infrastructure.
/// Each consuming target provides its own concrete `LogEntry` type.
package protocol LogEntryRepresentable {
    var created: Date { get }
    var message: String { get }
    var millisecondsSince1970: Int { get }
}
