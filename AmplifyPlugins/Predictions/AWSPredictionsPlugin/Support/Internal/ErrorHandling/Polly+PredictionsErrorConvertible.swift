//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly
import Amplify

extension AWSPolly.InvalidSampleRateException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.invalidSampleRate)
    }
}

extension AWSPolly.LanguageNotSupportedException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.unsupportedLanguage)
    }
}

extension AWSPolly.ServiceFailureException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.internalServerError)
    }
}

extension AWSPolly.TextLengthExceededException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.textSizeLimitExceeded)
    }
}

extension AWSPolly.LexiconNotFoundException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "Amazon Polly can't find the specified lexicon. This could be caused by a lexicon that is missing, its name is misspelled or specifying a lexicon that is in a different region.",
                recoverySuggestion: "Verify that the lexicon exists, is in the region (see ListLexicons) and that you spelled its name is spelled correctly. Then try again.",
                underlyingError: self
            )
        )
    }
}

extension AWSPolly.MarksNotSupportedForFormatException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "Speech marks are not supported for the OutputFormat selected.",
                recoverySuggestion: "Speech marks are only available for content in json format.",
                underlyingError: self
            )
        )
    }
}

extension AWSPolly.InvalidSsmlException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The SSML you provided is invalid.",
                recoverySuggestion: "Verify the SSML syntax, spelling of tags and values, and then try again.",
                underlyingError: self
            )
        )
    }
}

extension AWSPolly.SsmlMarksNotSupportedForTextTypeException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "SSML speech marks are not supported for plain text-type input.",
                recoverySuggestion: "",
                underlyingError: self
            )
        )
    }
}

extension AWSPolly.EngineNotSupportedException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "This engine is not compatible with the voice that you have designated.",
                recoverySuggestion: "Choose a new voice that is compatible with the engine or change the engine and restart the operation.",
                underlyingError: self
            )
        )
    }
}
