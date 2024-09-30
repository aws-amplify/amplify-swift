//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import enum AwsCommonRuntimeKit.CommonRunTimeError
import protocol SmithyRetriesAPI.RetryErrorInfoProvider
import enum ClientRuntime.DefaultRetryErrorInfoProvider
import struct SmithyRetriesAPI.RetryErrorInfo
import protocol ClientRuntime.ServiceError
import protocol ClientRuntime.HTTPError
import protocol ClientRuntime.ModeledError

public enum AWSRetryErrorInfoProvider: RetryErrorInfoProvider {

    // Error codes that the Retry Behavior 2.0 specification say should be treated as throttling errors.
    private static let throttlingErrorCodes = [
        "Throttling",
        "ThrottlingException",
        "ThrottledException",
        "RequestThrottledException",
        "TooManyRequestsException",
        "ProvisionedThroughputExceededException",
        "TransactionInProgressException",
        "RequestLimitExceeded",
        "BandwidthLimitExceeded",
        "LimitExceededException",
        "RequestThrottled",
        "SlowDown",
        "PriorRequestNotComplete",
        "EC2ThrottledException",
    ]

    // Error codes that the Retry Behavior 2.0 specification say should be treated as transient errors.
    private static let transientErrorCodes = [
        "RequestTimeout",
        "InternalError",
        "RequestTimeoutException",
    ]

    // CRT error codes that should be treated as transient errors.
    private static let transientCRTErrorCodes: [Int32] = [
        2058, // httpConnectionClosed
        2070, // httpServerClosed
    ]

    // HTTP status codes that the Retry Behavior 2.0 specification say should be treated as transient errors.
    private static let transientStatusCodes = [500, 502, 503, 504]

    // HTTP status codes should be treated as timeouts.
    private static let timeoutStatusCodes = [408, 504]

    public static func errorInfo(for error: Error) -> RetryErrorInfo? {

        // Look for a header with a retry after value; use it as retry after hint
        var retryAfterHint: TimeInterval?
        if let headers = (error as? HTTPError)?.httpResponse.headers,
           let delayString = headers.value(for: "Retry-After") ?? headers.value(for: "X-Amz-Retry-After"),
           let delay = TimeInterval(delayString) {
            retryAfterHint = delay
        }

        // Determine based on properties if this error is a timeout error.
        var isTimeout = false

        // Error can be a timeout error based on HTTP code
        if let httpError = error as? HTTPError,
           timeoutStatusCodes.contains(httpError.httpResponse.statusCode.rawValue) {
            isTimeout = true
        }

        // Handle certain CRT errors as transient errors
        if case CommonRunTimeError.crtError(let crtError) = error {
            if transientCRTErrorCodes.contains(crtError.code) {
                return RetryErrorInfo(errorType: .transient, retryAfterHint: retryAfterHint, isTimeout: isTimeout)
            }
        }

        if let serviceError = error as? ServiceError, let code = serviceError.typeName {
            // Handle the throttling error codes as errors of retry type "throttling".
            if throttlingErrorCodes.contains(code) {
                return RetryErrorInfo(errorType: .throttling, retryAfterHint: retryAfterHint, isTimeout: false)
            }
            // Handle the transient error codes as errors of retry type "transient".
            if transientErrorCodes.contains(code) {
                return RetryErrorInfo(errorType: .transient, retryAfterHint: retryAfterHint, isTimeout: isTimeout)
            }
        }

        if let httpError = error as? HTTPError {
            // Handle the transient and timeout HTTP status codes as errors of retry type "transient".
            if (transientStatusCodes + timeoutStatusCodes).contains(httpError.httpResponse.statusCode.rawValue) {
                return RetryErrorInfo(errorType: .transient, retryAfterHint: retryAfterHint, isTimeout: isTimeout)
            }
        }

        if let modeledError = error as? ModeledError, type(of: modeledError).typeName == "IDPCommunicationError" {

            // Handle a modeled IDPCommunicationError (comes from STS) as an error of retry type "transient".
            return RetryErrorInfo(errorType: .transient, retryAfterHint: retryAfterHint, isTimeout: isTimeout)
        }

        // If custom AWS error matching fails, use the default error info provider to finish matching.
        return DefaultRetryErrorInfoProvider.errorInfo(for: error)
    }
}
