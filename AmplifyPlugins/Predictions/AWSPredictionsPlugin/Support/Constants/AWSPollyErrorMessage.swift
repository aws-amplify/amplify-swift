//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPolly

typealias AWSPollyErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSPollyErrorMessage {

    static let languageNotSupported: AWSPollyErrorString = (
        "The language specified is not currently supported by Amazon Polly in this capacity.",
        """
        For a list of supported languages, check
        https://docs.aws.amazon.com/polly/latest/dg/SupportedLanguage.html.
        """
    )

    static let textLengthExceeded: AWSPollyErrorString = (
        "The string of text sent in is longer than the accepted limits.",
        "The limit for input text is a maximum of 6000 characters total.")

    static func map(_ errorType: AWSPollyErrorType) -> PredictionsError? {
        switch errorType {
        case .languageNotSupported:
            return PredictionsError.service(languageNotSupported.errorDescription,
                                            languageNotSupported.recoverySuggestion)
        case .serviceFailure:
            return PredictionsError.service(AWSServiceErrorMessage.resourceUnavailable.errorDescription,
                                            AWSServiceErrorMessage.resourceUnavailable.recoverySuggestion)
        case .textLengthExceeded:
            return PredictionsError.service(textLengthExceeded.errorDescription,
                                                 textLengthExceeded.recoverySuggestion)
        case .unknown:
            return PredictionsError.unknown("An unknown error occurred.", "")
        default:
            return nil
        }
    }
}
