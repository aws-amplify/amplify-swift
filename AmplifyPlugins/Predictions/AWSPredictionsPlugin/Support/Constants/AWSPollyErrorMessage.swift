//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPolly

typealias AWSPollyErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSPollyErrorMessage {
    
    static let languageNotSupported: AWSPollyErrorString = (
        "The language specified is not currently supported by Amazon Polly in this capacity.",
        "For a list of supported languages, check here https://docs.aws.amazon.com/polly/latest/dg/SupportedLanguage.html.")
    
    static let serviceFailure: AWSPollyErrorString = (
        "An unknown condition has caused a service failure.",
        "Please check to see if there is an outage at https://status.aws.amazon.com/ and reach out to AWS support.")
    
    static let textLengthExceeded: AWSPollyErrorString = (
        "The string of text sent in is longer than the accepted limits.",
        "The limit for input text is a maximum of 6000 characters total.")
    
    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSPollyErrorType) -> PredictionsError? {
        switch errorType {
        case .languageNotSupported:
            return PredictionsError.serviceError(
                languageNotSupported.errorDescription,
                languageNotSupported.recoverySuggestion)
        case .serviceFailure:
            return PredictionsError.serviceError(
                serviceFailure.errorDescription,
                serviceFailure.recoverySuggestion)
        case .textLengthExceeded:
            return PredictionsError.serviceError(
                textLengthExceeded.errorDescription,
                textLengthExceeded.recoverySuggestion)
        case .unknown:
            return PredictionsError.unknownError("An unknown error occurred.", "")
        default:
            return nil
        }
    }
}
