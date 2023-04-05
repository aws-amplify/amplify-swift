//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
import Amplify

typealias AWSTranslateErrorMessageString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSTranslateErrorMessage {
    static let accessDenied: AWSTranslateErrorMessageString = (
        "Access denied. You do not have sufficient access to perform this action.",
        "Please check that your Cognito IAM role has permissions to access Translate.")

    static let sourceLanguageNotProvided: AWSTranslateErrorMessageString = (
        "Source language is not provided",
        "Provide a supported source language")

    static let targetLanguageNotProvided: AWSTranslateErrorMessageString = (
        "Target language is not provided",
        "Provide a supported target language")

    static let detectedLanguageLowConfidence: AWSTranslateErrorMessageString = (
        "A language was detected but with very low confidence",
        "Please make sure you sent in one of the available languages for Translate")

    static let invalidParameterValue: AWSTranslateErrorMessageString = (
        "An invalid or out-of-range value was supplied for the input parameter.",
        "Please check your request and try again.")

    static let invalidRequest: AWSTranslateErrorMessageString = (
        "An invalid request was sent.",
        "Please check your request and try again.")

    static let textSizeLimitExceeded: AWSTranslateErrorMessageString = (
        "The size of the text string exceeded the limit. The limit is the first 256 terms in a string of text.",
        "Please send a shorter text string.")

    static let noTranslateTextResult: AWSTranslateErrorMessageString = (
           "No result was found.",
           """
            Please make sure a text string was sent over and that the target language was different
            from the language sent.
            """)

    static let tooManyRequests: AWSTranslateErrorMessageString = (
        """
        Too many requests made, the limit of requests was exceeded.
        Please check the limits here
        https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_amazon_translate
        """,
        "Please decrease the number of requests and try again.")

    static let unsupportedLanguagePair: AWSTranslateErrorMessageString = (
        "Your target language and source language are an unsupported language pair.",
        """
        Please refer to this table to see supported language pairs
        https://docs.aws.amazon.com/translate/latest/dg/what-is.html.
        """)

    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSTranslateErrorType) -> PredictionsError? {
        switch errorType {
        case .detectedLanguageLowConfidence:
            return PredictionsError.service(detectedLanguageLowConfidence.errorDescription,
                                            detectedLanguageLowConfidence.recoverySuggestion)
        case .internalServer:
            return PredictionsError.service(AWSServiceErrorMessage.internalServerError.errorDescription,
                                            AWSServiceErrorMessage.internalServerError.recoverySuggestion)
        case .invalidParameterValue:
            return PredictionsError.service(invalidParameterValue.errorDescription,
                                            invalidParameterValue.recoverySuggestion)
        case .invalidRequest:
            return PredictionsError.service(invalidRequest.errorDescription,
                                            invalidRequest.recoverySuggestion)
        case .limitExceeded:
            return PredictionsError.service(AWSServiceErrorMessage.limitExceeded.errorDescription,
                                            AWSServiceErrorMessage.limitExceeded.recoverySuggestion)
        case .resourceNotFound:
            return PredictionsError.service(AWSServiceErrorMessage.resourceNotFound.errorDescription,
                                            AWSServiceErrorMessage.resourceNotFound.recoverySuggestion)
        case .serviceUnavailable:
            return PredictionsError.service(AWSServiceErrorMessage.resourceUnavailable.errorDescription,
                                            AWSServiceErrorMessage.resourceUnavailable.recoverySuggestion)
        case .textSizeLimitExceeded:
            return PredictionsError.service(textSizeLimitExceeded.errorDescription,
                                            textSizeLimitExceeded.recoverySuggestion)
        case .tooManyRequests:
            return PredictionsError.service(tooManyRequests.errorDescription,
                                            tooManyRequests.recoverySuggestion)
        case .unknown:
            return PredictionsError.unknown("An unknown error occurred.", "")
        case .unsupportedLanguagePair:
            return PredictionsError.service(unsupportedLanguagePair.errorDescription,
                                            unsupportedLanguagePair.recoverySuggestion)
        default:
            return nil
        }
    }
}
