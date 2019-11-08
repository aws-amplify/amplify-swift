//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class AWSDataStoreSyncEngineRetryPolicy: AWSDataStoreRetryable {
    static let maxWaitMilliseconds = 300 * 1_000 // 5 minutes of max retry duration.
    static let maxRetryAttemptsWhenUsingAggresiveMode = 30

    private static let jitterMilliseconds: Float = 100.0
    private var currentAttemptNumber = 0
    private var retryStrategy: AWSDataStoreRetryStrategy

    init(retryStrategy: AWSDataStoreRetryStrategy = .exponential) {
        self.retryStrategy = retryStrategy
    }

    //Largely a copy of AWSAppSyncRetryHandler
    func shouldRetryRequest(for error: AWSDataStoreClientError) -> AWSDataStoreRetryAdvice {
        currentAttemptNumber += 1

        var httpResponse: HTTPURLResponse?

        switch error {
        case .requestFailed(_, let reponse, _):
            httpResponse = reponse
        case .noData(let response):
            httpResponse = response
        case .parseError(_, let response, _):
            httpResponse = response
        case .authenticationError:
            httpResponse = nil
        }

        /// If no known error and we did not receive an HTTP response, we return false.
        guard let unwrappedResponse = httpResponse else {
            return AWSDataStoreRetryAdvice(shouldRetry: false, retryInterval: nil)
        }

        if let retryAfterValueInSeconds = AWSDataStoreSyncEngineRetryPolicy.getRetryAfterHeaderValue(from: unwrappedResponse) {
            return AWSDataStoreRetryAdvice(shouldRetry: true, retryInterval: .seconds(retryAfterValueInSeconds))
        }

        // If using aggressive retry strategy, we attempt a maximum 12 times.
        if retryStrategy == .aggressive &&
            currentAttemptNumber > AWSDataStoreSyncEngineRetryPolicy.maxRetryAttemptsWhenUsingAggresiveMode {
            return AWSDataStoreRetryAdvice(shouldRetry: false, retryInterval: nil)
        }

        let waitMillis = AWSDataStoreSyncEngineRetryPolicy.retryDelayInMillseconds(for: currentAttemptNumber, retryStrategy: retryStrategy)

        switch unwrappedResponse.statusCode {
        case 500 ... 599, 429:
            if waitMillis > AWSDataStoreSyncEngineRetryPolicy.maxWaitMilliseconds {
                break
            } else {
                return AWSDataStoreRetryAdvice(shouldRetry: true, retryInterval: .milliseconds(waitMillis))
            }
        default:
            break
        }
        return AWSDataStoreRetryAdvice(shouldRetry: false, retryInterval: nil)
    }

    /// Returns a delay in milliseconds for the current attempt number. The delay includes random jitter as
    /// described in https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
    private static func retryDelayInMillseconds(for attemptNumber: Int, retryStrategy: AWSDataStoreRetryStrategy) -> Int {
        let jitter = Double(getRandomBetween0And1() * jitterMilliseconds)
        switch retryStrategy {
        case .aggressive:
            let delay = Int(Double(1_000.0 + jitter))
            return delay
        case .exponential:
            let delay = Int(Double(truncating: pow(2.0, attemptNumber) as NSNumber) * 100.0 + jitter)
            return delay
        }
    }

    private static func getRandomBetween0And1() -> Float {
        return Float.random(in: 0 ... 1)
    }

    /// Returns the value of the "Retry-After" header as an Int, or nil if the value isn't present or cannot
    /// be converted to an Int
    ///
    /// - Parameter response: The response to get the header from
    /// - Returns: The value of the "Retry-After" header, or nil if not present or not convertable to Int
    private static func getRetryAfterHeaderValue(from response: HTTPURLResponse) -> Int? {
        let waitTime: Int?
        switch response.allHeaderFields["Retry-After"] {
        case let retryTime as String:
            waitTime = Int(retryTime)
        case let retryTime as Int:
            waitTime = retryTime
        default:
            waitTime = nil
        }

        return waitTime
    }

    // This function is largely a copy of AWSMutationRetryAdviceHelper
    func shouldRetryMutationRequest(for error: Error) -> AWSDataStoreRetryAdvice {
        if let appsyncError = error as? AWSDataStoreClientError {
            switch appsyncError {
            case .authenticationError(let authError):
                // We are currently checking for this error due to IAM auth.
                // If Cognito Identity SDK does not have an identity id available,
                // It tries to get one before giving the callback to appsync SDK.
                // If Cognito Identity SDK cannot reach the service to fetch identityd id,
                // it will propogate the error it encoutered to AppSync. We specifically
                // check if the error is of type internet not available and then retry.
                return AWSDataStoreSyncEngineRetryPolicy.isErrorURLDomainError(error: authError)
            case .requestFailed(_, _, let urlError):
                if let urlError = urlError {
                    return AWSDataStoreSyncEngineRetryPolicy.isErrorURLDomainError(error: urlError)
                }
            default:
                break
            }
        } else {
            return AWSDataStoreSyncEngineRetryPolicy.isErrorURLDomainError(error: error)
        }
        return AWSDataStoreRetryAdvice(shouldRetry: false, retryInterval: nil)
    }

    /// We evaluate the error against known error codes which could result due to
    /// unavailable internet or spotty network connection.
    private static func isErrorURLDomainError(error: Error) -> AWSDataStoreRetryAdvice {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return AWSDataStoreRetryAdvice(shouldRetry: false, retryInterval: nil)
        }
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorDNSLookupFailed,
             NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorTimedOut:
            //TODO: In the AWSMutationRetryAdviceHelper implementation, there was no exponential
            // backoff.  We could easily implement one here if needed, but to get some
            // feedback quickly, I decided to just a 25ms delay here.
            return AWSDataStoreRetryAdvice(shouldRetry: false, retryInterval: .milliseconds(25))
        default:
            break
        }
        return AWSDataStoreRetryAdvice(shouldRetry: false, retryInterval: nil)
    }
}
