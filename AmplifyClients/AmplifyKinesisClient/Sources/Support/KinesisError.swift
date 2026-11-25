//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyRecordCache
import Foundation

/// Top-level error type for KinesisDataStreams operations.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
public enum KinesisError {

  /// A local cache/storage error.
  case cache(ErrorDescription, RecoverySuggestion, Error? = nil)
  /// Cache limit exceeded — no space for new records.
  case cacheLimitExceeded(ErrorDescription, RecoverySuggestion, Error? = nil)
  /// Record input validation failed (e.g. oversized record, invalid partition key).
  case validation(ErrorDescription, RecoverySuggestion, Error? = nil)
  /// The credentials provider threw AmplifyFoundation's `CredentialsError`, which stopped the flush. The
  /// description and recovery suggestion are the provider's, and the underlying error is that error. No retry
  /// is counted against the records left in the cache; see `flush()` for what happens to them. To read the
  /// error's `disposition`, cast `underlyingError` to `CredentialsError`, which is experimental SPI and needs
  /// `@_spi(AmplifyExperimental) import AmplifyFoundation`.
  case credentials(ErrorDescription, RecoverySuggestion, Error? = nil)
  /// An error that doesn't fall into the known categories above.
  case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension KinesisError: AmplifyError {
  public var errorDescription: ErrorDescription {
    switch self {
    case .cache(let description, _, _),
      .cacheLimitExceeded(let description, _, _),
      .validation(let description, _, _),
      .credentials(let description, _, _),
      .unknown(let description, _, _):
      return description
    }
  }

  public var recoverySuggestion: RecoverySuggestion {
    switch self {
    case .cache(_, let suggestion, _),
      .cacheLimitExceeded(_, let suggestion, _),
      .validation(_, let suggestion, _),
      .credentials(_, let suggestion, _),
      .unknown(_, let suggestion, _):
      return suggestion
    }
  }

  public var underlyingError: Error? {
    switch self {
    case .cache(_, _, let error),
      .cacheLimitExceeded(_, _, let error),
      .validation(_, _, let error),
      .credentials(_, _, let error),
      .unknown(_, _, let error):
      return error
    }
  }

  public init(
    errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion,
    error: Error?
  ) {
    if let error = error as? Self {
      self = error
    } else {
      self = .unknown(errorDescription, recoverySuggestion, error)
    }
  }

  /// Maps a raw error into a KinesisError, handling RecordCacheError and unknown errors.
  static func from(_ error: Error) -> KinesisError {
    if let kinesisError = error as? KinesisError {
      return kinesisError
    }

    if let cacheError = error as? RecordCacheError {
      return fromCacheError(cacheError)
    }

    return .unknown(
      "An unknown error occurred",
      defaultRecoverySuggestion,
      error
    )
  }

  private static func fromCacheError(_ cacheError: RecordCacheError) -> KinesisError {
    switch cacheError {
    case .database(let desc, let recovery, let underlyingError):
      return .cache(desc, recovery, underlyingError)
    case .limitExceeded(let desc, let recovery, let underlyingError):
      return .cacheLimitExceeded(desc, recovery, underlyingError)
    case .validation(let desc, let recovery, let underlyingError):
      return .validation(desc, recovery, underlyingError)
    case .credentials(let desc, let recovery, let underlyingError):
      return .credentials(desc, recovery, underlyingError)
    }
  }
}
