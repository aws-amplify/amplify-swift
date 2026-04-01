//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Internal error type used by RecordClient/RecordStorage.
/// Mapped to a client-specific error type (e.g. KinesisError, FirehoseError).
public enum RecordCacheError: Error {
    /// Database operation failed.
    case database(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Cache limit exceeded — no space for new records.
    case limitExceeded(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Record input validation failed (e.g. oversized record, invalid partition key).
    case validation(ErrorDescription, RecoverySuggestion, Error? = nil)
}
