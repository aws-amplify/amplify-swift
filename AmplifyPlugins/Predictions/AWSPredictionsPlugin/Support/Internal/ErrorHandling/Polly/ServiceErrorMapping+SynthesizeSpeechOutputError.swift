//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly
import Amplify

extension ServiceErrorMapping where T == SynthesizeSpeechOutputError {
    static let synthesizeSpeech: Self = .init { error in
        switch error {
        case .invalidSampleRateException:
            return PredictionsError.service(.invalidSampleRate)
        case .languageNotSupportedException:
            return PredictionsError.service(.unsupportedLanguage)
        case .serviceFailureException:
            return PredictionsError.service(.internalServerError)
        case .textLengthExceededException:
            return PredictionsError.service(.textSizeLimitExceeded)
        case .lexiconNotFoundException:
            return PredictionsError.service(
                .init(
                    description: "Amazon Polly can't find the specified lexicon. This could be caused by a lexicon that is missing, its name is misspelled or specifying a lexicon that is in a different region.",
                    recoverySuggestion: "Verify that the lexicon exists, is in the region (see ListLexicons) and that you spelled its name is spelled correctly. Then try again.",
                    underlyingError: error
                )
            )
        case .marksNotSupportedForFormatException:
            return PredictionsError.service(
                .init(
                    description: "Speech marks are not supported for the OutputFormat selected.",
                    recoverySuggestion: "Speech marks are only available for content in json format.",
                    underlyingError: error
                )
            )
        case .invalidSsmlException:
            return PredictionsError.service(
                .init(
                    description: "The SSML you provided is invalid.",
                    recoverySuggestion: "Verify the SSML syntax, spelling of tags and values, and then try again.",
                    underlyingError: error
                )
            )
        case .ssmlMarksNotSupportedForTextTypeException:
            return PredictionsError.service(
                .init(
                    description: "SSML speech marks are not supported for plain text-type input.",
                    recoverySuggestion: "",
                    underlyingError: error
                )
            )
        case .engineNotSupportedException:
            return PredictionsError.service(
                .init(
                    description: "This engine is not compatible with the voice that you have designated.",
                    recoverySuggestion: "Choose a new voice that is compatible with the engine or change the engine and restart the operation.",
                    underlyingError: error
                )
            )
        case .unknown:
            return PredictionsError.unknownServiceError(error)
        }
    }
}
