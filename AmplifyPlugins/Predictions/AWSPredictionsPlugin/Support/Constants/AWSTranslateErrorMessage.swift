//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
import Amplify

typealias AWSTranslateErrorMessageString = (ErrorDescription, RecoverySuggestion)

struct AWSTranslateErrorMessage {
    static let accessDenied: AWSComprehendErrorString = (
        "Access denied!",
        "Please check that your Cognito IAM role has permissions to access Translate.")
    
    static let detectedLanguageLowConfidence: AWSComprehendErrorString = (
        "A language was detected but with very low confidence",
        "Please make sure you sent in one of the available languages for Translate")
    
    static let internalServerError: AWSComprehendErrorString = (
        "An internal server error occurred",
        """
        Please take a look at https://github.com/aws-amplify/amplify-ios/issues to see if there are any
        existing issues that match your scenario, and file an issue with the details of the bug if there isn't.
        """)
    
    static let invalidParameterValue: AWSComprehendErrorString = (
        "An invalid parameter value was given",
        "Please check your request and try again.")
    
    static let invalidRequest: AWSComprehendErrorString = (
        "An invalid request was sent.",
        "Please check your request and try again.")
    
    static let limitExceeded: AWSComprehendErrorString = (
        "The number of requests made has exceeded the limit.",
        "Please decrease the number of requests and try again.")
    
    static let resourceNotFound: AWSComprehendErrorString = (
        "Your resource was not found.",
        "Please make sure you either created the resource using the Amplify CLI or the AWS Console")
    
    static let serviceUnavailable: AWSComprehendErrorString = (
        "The service is currently unavailable.",
        "Please check to see if there is an outage at https://status.aws.amazon.com/ and reach out to AWS support.")

    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSTranslateErrorType) -> PredictionsError? {
        switch errorType {
        case .detectedLanguageLowConfidence:
            return PredictionsError.serviceError(
                detectedLanguageLowConfidence.errorDescription,
                detectedLanguageLowConfidence.recoverySuggestion)
        case .internalServer:
            return PredictionsError.serviceError(
                internalServerError.errorDescription,
                internalServerError.recoverySuggestion)
        case .invalidParameterValue:
            return PredictionsError.serviceError(
                invalidParameterValue.errorDescription,
                invalidParameterValue.recoverySuggestion)
        case .invalidRequest:
            return PredictionsError.serviceError(
                invalidRequest.errorDescription,
                invalidRequest.recoverySuggestion)
        case .limitExceeded:
            return PredictionsError.serviceError(
                limitExceeded.errorDescription,
                limitExceeded.recoverySuggestion)
        case .resourceNotFound:
            return PredictionsError.serviceError(
                resourceNotFound.errorDescription,
                resourceNotFound.recoverySuggestion)
        case .serviceUnavailable:
            return PredictionsError.serviceError(
                serviceUnavailable.errorDescription,
                serviceUnavailable.recoverySuggestion)
        case .textSizeLimitExceeded:
            break
        case .tooManyRequests:
            break
        case .unknown:
            break
        case .unsupportedLanguagePair:
            break
        default:
            return nil
        }
        return nil
    }
}
