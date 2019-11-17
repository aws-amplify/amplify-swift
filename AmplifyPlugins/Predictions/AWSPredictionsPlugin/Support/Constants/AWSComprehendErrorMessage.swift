//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSComprehend

typealias AWSComprehendErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSComprehendErrorMessage {
    static let accessDenied: AWSComprehendErrorString = (
        "Access denied!",
        "")

    static let noLanguageFound: AWSComprehendErrorString = (
        "No result was found for language. An unknown error occurred.",
        "Please try with different input")

    static let dominantLanguageNotDetermined: AWSComprehendErrorString = (
        "Could not determine the predominant language in the text",
        "Please try with different input")

    static let batchSizeLimitExceeded: AWSComprehendErrorString = (
        "The size of the request was too large",
        "Please decrease the size of the request and try again")

    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSComprehendErrorType) -> PredictionsError? {
        switch errorType {
        case .batchSizeLimitExceeded:
            return PredictionsError.serviceError(
                batchSizeLimitExceeded.errorDescription,
                batchSizeLimitExceeded.recoverySuggestion)
        case .concurrentModification:
            break
        case .internalServer:
            return PredictionsError.internalServiceError("", "")
        case .invalidFilter:
            break
        case .invalidRequest:
            break
        case .jobNotFound:
            break
        case .kmsKeyValidation:
            break
        case .resourceInUse:
            break
        case .resourceLimitExceeded:
            break
        case .resourceNotFound:
            break
        case .resourceUnavailable:
            break
        case .textSizeLimitExceeded:
            break
        case .tooManyRequests:
            break
        case .tooManyTagKeys:
            break
        case .tooManyTags:
            break
        case .unknown:
            break
        case .unsupportedLanguage:
            break
        @unknown default:
            break
        }
        return nil
    }
}
