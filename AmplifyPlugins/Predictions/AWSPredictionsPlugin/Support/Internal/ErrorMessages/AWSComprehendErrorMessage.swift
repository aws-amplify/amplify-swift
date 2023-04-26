//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
        "Please try with different input"
    )

    static let dominantLanguageNotDetermined: AWSComprehendErrorString = (
        "Could not determine the predominant language in the text",
        "Please try with different input")

    static let invalidRequest: AWSComprehendErrorString = (
        "An invalid request was sent.",
        "Please check your request and try again."
    )

    static let resourceInUse: AWSComprehendErrorString = (
        "The resource is already in use.",
        "Retry when the resource is available."
    )

    static let limitExceeded: AWSComprehendErrorString = (
        "The request exceeded the service limits.",
        """
        Decrease the number of calls you are making or make sure your request is below the service limits for your
        region. Check the limits here:
        https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_amazon_comprehend
        """
    )

    static let textSizeLimitExceeded: AWSComprehendErrorString = (
        "The size of the input text exceeds the limit.",
        "Use a smaller document."
    )

    static let unsupportedLanguage: AWSComprehendErrorString = (
        "Amazon Comprehend can't process the language of the input text.",
        """
        For a list of supported languages, check:
        https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html.
        """
    )

    static func map(_ errorType: AWSComprehendErrorType) -> PredictionsError? {
        switch errorType {
        case .internalServer:
            return PredictionsError.service(AWSServiceErrorMessage.internalServerError.errorDescription,
                                            AWSServiceErrorMessage.internalServerError.recoverySuggestion)
        case .invalidRequest:
            return PredictionsError.service(invalidRequest.errorDescription,
                                            invalidRequest.recoverySuggestion)
        case .resourceInUse:
            return PredictionsError.service(resourceInUse.errorDescription,
                                            resourceInUse.recoverySuggestion)
        case .resourceLimitExceeded,
             .tooManyRequests:
            return PredictionsError.service(limitExceeded.errorDescription,
                                            limitExceeded.recoverySuggestion)
        case .resourceNotFound:
            return PredictionsError.service(AWSServiceErrorMessage.resourceNotFound.errorDescription,
                                            AWSServiceErrorMessage.resourceNotFound.recoverySuggestion)
        case .resourceUnavailable:
            return PredictionsError.service(AWSServiceErrorMessage.resourceUnavailable.errorDescription,
                                            AWSServiceErrorMessage.resourceUnavailable.recoverySuggestion)
        case .textSizeLimitExceeded:
            return PredictionsError.service(textSizeLimitExceeded.errorDescription,
                                            textSizeLimitExceeded.recoverySuggestion)
        case .unknown:
            return PredictionsError.unknown("An unknown error occurred.", "")
        case .unsupportedLanguage:
            return PredictionsError.service(unsupportedLanguage.errorDescription,
                                            unsupportedLanguage.recoverySuggestion)
        }
    }
}

enum AWSComprehendErrorType {
    case internalServer
    case invalidRequest
    case resourceInUse
    case resourceLimitExceeded
    case tooManyRequests
    case resourceNotFound
    case resourceUnavailable
    case textSizeLimitExceeded
    case unknown
    case unsupportedLanguage
}

