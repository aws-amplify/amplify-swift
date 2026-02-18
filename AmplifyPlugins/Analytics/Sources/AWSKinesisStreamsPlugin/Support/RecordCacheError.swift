//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Default recovery suggestion for errors.
let defaultRecoverySuggestion: RecoverySuggestion = "Inspect the underlying error for more details."

/// Internal error type used by RecordClient/RecordStorage.
/// Mapped to KinesisError via ``KinesisError/from(_:)``.
internal enum RecordCacheError: Error {
    /// Database operation failed.
    case database(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Cache limit exceeded — no space for new records.
    case limitExceeded(ErrorDescription, RecoverySuggestion, Error? = nil)
}
