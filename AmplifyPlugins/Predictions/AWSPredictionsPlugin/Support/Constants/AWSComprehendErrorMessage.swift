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
    
    static let noLanguageFound: AWSComprehendErrorString = (
        "No result was found for language. An unknown error occurred.",
        "Please try with different input")
    
    static let dominantLanguageNotDetermined: AWSComprehendErrorString = (
        "Could not determine the predominant language in the text",
        "Please try with different input")
    
    static let batchSizeLimitExceeded: AWSComprehendErrorString = (
        "The size of the request was too large",
        "Please decrease the size of the request and try again")
    
    static let resourceNotFound: AWSComprehendErrorString = (
        "Your resource was not found.",
        "Please make sure you either created the resource using the Amplify CLI or the AWS Console")
    
    static let invalidRequest: AWSComprehendErrorString = (
        "An invalid request was sent.",
        "Please check your request and try again.")
    
    static let resourceInUse: AWSComprehendErrorString = (
        "The resource is already in use.",
        "Retry when the resource is available.")
    
    static let limitExceeded: AWSComprehendErrorString = (
        "The request exceeded the service limits.",
        """
        Decrease the number of calls you are making or make sure your request is below the service limits for your region.
        Check the limits here:
        https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_amazon_comprehend
        """)
    
    static let resourceUnavailable: AWSComprehendErrorString = (
        "The resource is currently unavailable.",
        "Please check to see if there is an outage at https://status.aws.amazon.com/ and reach out to AWS support.")
    
    static let textSizeLimitExceeded: AWSComprehendErrorString = (
        "The size of the input text exceeds the limit.",
        "Use a smaller document.")
    
    static let unsupportedLanguage: AWSComprehendErrorString = (
        "Amazon Comprehend can't process the language of the input text.",
        "For a list of supported languages, check here https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html.")
    
    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSComprehendErrorType) -> PredictionsError? {
        switch errorType {
        case .batchSizeLimitExceeded:
            return PredictionsError.serviceError(
                batchSizeLimitExceeded.errorDescription,
                batchSizeLimitExceeded.recoverySuggestion)
        case .internalServer:
            return PredictionsError.internalServiceError("", "")
        case .invalidRequest:
            return PredictionsError.serviceError(
                invalidRequest.errorDescription,
                invalidRequest.recoverySuggestion)
        case .resourceInUse:
            return PredictionsError.serviceError(
                resourceInUse.errorDescription,
                resourceInUse.recoverySuggestion)
        case .resourceLimitExceeded,
             .tooManyRequests:
            return PredictionsError.serviceError(
                limitExceeded.errorDescription,
                limitExceeded.recoverySuggestion)
        case .resourceNotFound:
            return PredictionsError.serviceError(
                resourceNotFound.errorDescription,
                resourceNotFound.recoverySuggestion)
        case .resourceUnavailable:
            return PredictionsError.serviceError(
                resourceUnavailable.errorDescription,
                resourceUnavailable.recoverySuggestion)
        case .textSizeLimitExceeded:
            return PredictionsError.serviceError(
                textSizeLimitExceeded.errorDescription,
                textSizeLimitExceeded.recoverySuggestion)
        case .unknown:
            return PredictionsError.unknownError("An unknown error occurred.", "")
        case .unsupportedLanguage:
            return PredictionsError.serviceError(
                unsupportedLanguage.errorDescription,
                unsupportedLanguage.recoverySuggestion)
        default:
            return nil
        }
    }
}
