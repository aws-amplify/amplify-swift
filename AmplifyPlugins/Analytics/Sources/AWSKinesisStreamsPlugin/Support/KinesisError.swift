//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSKinesis
import Foundation

/// Errors that can occur during a [`PutRecords`](https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html) operation.
public enum KinesisPutRecordsSdkError: Error {
    /// You do not have the permissions required to perform this operation.
    case accessDenied(AccessDeniedException)
    /// The processing of the request failed because of an unknown error, exception, or failure.
    case internalFailure(InternalFailureException)
    /// A specified parameter exceeds its restrictions, is not supported, or can't be used.
    case invalidArgument(InvalidArgumentException)
    /// The ciphertext references a key that doesn't exist or that you don't have access to.
    case kmsAccessDenied(KMSAccessDeniedException)
    /// The specified customer master key (CMK) isn't enabled.
    case kmsDisabled(KMSDisabledException)
    /// The state of the specified resource isn't valid for this request.
    case kmsInvalidState(KMSInvalidStateException)
    /// The specified entity or resource can't be found.
    case kmsNotFound(KMSNotFoundException)
    /// The AWS access key ID needs a subscription for the service.
    case kmsOptInRequired(KMSOptInRequired)
    /// The request was denied due to request throttling.
    case kmsThrottling(KMSThrottlingException)
    /// The request rate for the stream is too high, or the requested data is too large.
    case provisionedThroughputExceeded(ProvisionedThroughputExceededException)
    /// The requested resource could not be found.
    case resourceNotFound(ResourceNotFoundException)
    /// An unexpected SDK error.
    case unknown(Error)
}

/// Top-level error type for KinesisDataStreams operations.
public enum KinesisError {

    /// A typed error returned by the Kinesis service during a PutRecords call.
    case service(ErrorDescription, RecoverySuggestion, KinesisPutRecordsSdkError)
    /// A local cache/storage error.
    case cache(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Cache limit exceeded — no space for new records.
    case cacheLimitExceeded(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// An error that doesn't fall into the known categories above.
    case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension KinesisError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .service(let description, _, _),
             .cache(let description, _, _),
             .cacheLimitExceeded(let description, _, _),
             .unknown(let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .service(_, let suggestion, _),
             .cache(_, let suggestion, _),
             .cacheLimitExceeded(_, let suggestion, _),
             .unknown(_, let suggestion, _):
            return suggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .service(_, _, let error):
            return error
        case .cache(_, _, let error),
             .cacheLimitExceeded(_, _, let error),
             .unknown(_, _, let error):
            return error
        }
    }

    public init(
        errorDescription: ErrorDescription,
        recoverySuggestion: RecoverySuggestion,
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, recoverySuggestion, error)
        }
    }

    /// Maps a raw error into a KinesisError, handling RecordCacheError, Kinesis SDK exceptions, and unknown errors.
    static func from(_ error: Error) -> KinesisError {
        if let kinesisError = error as? KinesisError {
            return kinesisError
        }

        if let cacheError = error as? RecordCacheError {
            return fromCacheError(cacheError)
        }

        guard let sdkError = mapToSdkError(error) else {
            return .unknown(
                "An unknown error occurred",
                defaultRecoverySuggestion,
                error
            )
        }
        return .service(
            "A service error occurred",
            defaultRecoverySuggestion,
            sdkError
        )
    }

    private static func fromCacheError(_ cacheError: RecordCacheError) -> KinesisError {
        switch cacheError {
        case .database(let desc, let recovery, let underlyingError):
            return .cache(desc, recovery, underlyingError)
        case .limitExceeded(let desc, let recovery, let underlyingError):
            return .cacheLimitExceeded(desc, recovery, underlyingError)
        }
    }

    private static func mapToSdkError(_ error: Error) -> KinesisPutRecordsSdkError? {
        switch error {
        case let err as AccessDeniedException:
            return .accessDenied(err)
        case let err as InternalFailureException:
            return .internalFailure(err)
        case let err as InvalidArgumentException:
            return .invalidArgument(err)
        case let err as KMSAccessDeniedException:
            return .kmsAccessDenied(err)
        case let err as KMSDisabledException:
            return .kmsDisabled(err)
        case let err as KMSInvalidStateException:
            return .kmsInvalidState(err)
        case let err as KMSNotFoundException:
            return .kmsNotFound(err)
        case let err as KMSOptInRequired:
            return .kmsOptInRequired(err)
        case let err as KMSThrottlingException:
            return .kmsThrottling(err)
        case let err as ProvisionedThroughputExceededException:
            return .provisionedThroughputExceeded(err)
        case let err as ResourceNotFoundException:
            return .resourceNotFound(err)
        default:
            return nil
        }
    }
}
