//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSKinesis
import Foundation

/// Top-level error type for KinesisDataStreams operations.
public enum KinesisError {

  /// A local cache/storage error.
  case cache(ErrorDescription, RecoverySuggestion, Error? = nil)
  /// Cache limit exceeded — no space for new records.
  case cacheLimitExceeded(ErrorDescription, RecoverySuggestion, Error? = nil)
  /// Record input validation failed (e.g. oversized record, invalid partition key).
  case validation(ErrorDescription, RecoverySuggestion, Error? = nil)
  /// An error that doesn't fall into the known categories above.
  case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension KinesisError: AmplifyError {
  public var errorDescription: ErrorDescription {
    switch self {
    case .cache(let description, _, _),
      .cacheLimitExceeded(let description, _, _),
      .validation(let description, _, _),
      .unknown(let description, _, _):
      return description
    }
  }

  public var recoverySuggestion: RecoverySuggestion {
    switch self {
    case .cache(_, let suggestion, _),
      .cacheLimitExceeded(_, let suggestion, _),
      .validation(_, let suggestion, _),
      .unknown(_, let suggestion, _):
      return suggestion
    }
  }

  public var underlyingError: Error? {
    switch self {
    case .cache(_, _, let error),
      .cacheLimitExceeded(_, _, let error),
      .validation(_, _, let error),
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

  /// Returns true if the error originates from the Kinesis SDK.
  static func isSdkError(_ error: Error) -> Bool {
    return error is AccessDeniedException
      || error is InternalFailureException
      || error is InvalidArgumentException
      || error is KMSAccessDeniedException
      || error is KMSDisabledException
      || error is KMSInvalidStateException
      || error is KMSNotFoundException
      || error is KMSOptInRequired
      || error is KMSThrottlingException
      || error is ProvisionedThroughputExceededException
      || error is ResourceNotFoundException
  }

  private static func fromCacheError(_ cacheError: RecordCacheError) -> KinesisError {
    switch cacheError {
    case .database(let desc, let recovery, let underlyingError):
      return .cache(desc, recovery, underlyingError)
    case .limitExceeded(let desc, let recovery, let underlyingError):
      return .cacheLimitExceeded(desc, recovery, underlyingError)
    case .validation(let desc, let recovery, let underlyingError):
      return .validation(desc, recovery, underlyingError)
    }
  }
}
