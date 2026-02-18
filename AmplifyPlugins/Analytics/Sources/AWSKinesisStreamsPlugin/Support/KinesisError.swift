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
            switch cacheError {
            case .database(let desc, let recovery, let underlyingError):
                return .cache(desc, recovery, underlyingError)
            case .limitExceeded(let desc, let recovery, let underlyingError):
                return .cacheLimitExceeded(desc, recovery, underlyingError)
            }
        }

        let sdkError: KinesisPutRecordsSdkError
        switch error {
        case let e as AccessDeniedException:
            sdkError = .accessDenied(e)
        case let e as InternalFailureException:
            sdkError = .internalFailure(e)
        case let e as InvalidArgumentException:
            sdkError = .invalidArgument(e)
        case let e as KMSAccessDeniedException:
            sdkError = .kmsAccessDenied(e)
        case let e as KMSDisabledException:
            sdkError = .kmsDisabled(e)
        case let e as KMSInvalidStateException:
            sdkError = .kmsInvalidState(e)
        case let e as KMSNotFoundException:
            sdkError = .kmsNotFound(e)
        case let e as KMSOptInRequired:
            sdkError = .kmsOptInRequired(e)
        case let e as KMSThrottlingException:
            sdkError = .kmsThrottling(e)
        case let e as ProvisionedThroughputExceededException:
            sdkError = .provisionedThroughputExceeded(e)
        case let e as ResourceNotFoundException:
            sdkError = .resourceNotFound(e)
        default:
            return .unknown(
                "An unknown error occured",
                defaultRecoverySuggestion,
                error
            )
        }
        return .service(
            "A service error occured",
            defaultRecoverySuggestion,
            sdkError
        )
    }
}
