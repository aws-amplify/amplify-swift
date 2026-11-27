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
package enum RecordCacheError: Error {
    /// Database operation failed.
    case database(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Cache limit exceeded — no space for new records.
    case limitExceeded(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Input validation failed (e.g. oversized record, invalid partition key, an empty cache identifier).
    case validation(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// The credentials provider could not vend credentials, so the flush stopped at the request it was sending
    /// (streams and batches sent before it stay sent). Carries the provider's description and recovery
    /// suggestion, and the provider's error (a `CredentialsError`) as the underlying one.
    case credentials(ErrorDescription, RecoverySuggestion, Error? = nil)
}
