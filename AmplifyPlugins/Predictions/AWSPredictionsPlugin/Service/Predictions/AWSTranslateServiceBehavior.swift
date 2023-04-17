//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranslate

protocol AWSTranslateServiceBehavior {
//    typealias TranslateTextServiceEventHandler = (TranslateTextServiceEvent) -> Void
//    typealias TranslateTextServiceEvent = PredictionsEvent<TranslateTextResult, PredictionsError>

    func translateText(
        text: String,
        language: LanguageType?,
        targetLanguage: LanguageType?
    ) async throws -> Predictions.Convert.TranslateText.Result
}
