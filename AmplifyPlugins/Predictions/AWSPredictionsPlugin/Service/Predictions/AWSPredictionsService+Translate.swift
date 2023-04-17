//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranslate

extension AWSPredictionsService: AWSTranslateServiceBehavior {

    func translateText(
        text: String,
        language: LanguageType?,
        targetLanguage: LanguageType?
    ) async throws -> Predictions.Convert.TranslateText.Result {
        // prefer passed in language. If it's not there, try to grab it from the config,
        // If that doesn't exist, we can't progress any further and throw an error
        guard let sourceLanguage = language ?? predictionsConfig.convert.translateText?.sourceLanguage else {
            throw PredictionsError.configuration(
                AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                nil
            )
        }

        // prefer passed in language. If it's not there, try to grab it from the config,
        // If that doesn't exist, we can't progress any further and throw an error
        guard let finalTargetLanguage = targetLanguage ?? predictionsConfig.convert.translateText?.targetLanguage else {
            throw PredictionsError.configuration(
                AWSTranslateErrorMessage.targetLanguageNotProvided.errorDescription,
                AWSTranslateErrorMessage.targetLanguageNotProvided.errorDescription,
                nil
            )
        }


        let request = TranslateTextInput(
            sourceLanguageCode: sourceLanguage.rawValue,
            targetLanguageCode: finalTargetLanguage.rawValue,
            text: text
        )

        let textTranslateResult: TranslateTextOutputResponse
        do {
            textTranslateResult = try await awsTranslate.translateText(request: request)
        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let translatedText = textTranslateResult.translatedText else {
            let noResult = AWSTranslateErrorMessage.noTranslateTextResult
            throw PredictionsError.network(noResult.errorDescription, noResult.recoverySuggestion)
        }

        let targetLanguage = LanguageType(rawValue: textTranslateResult.targetLanguageCode ?? "")
        let translateTextResult = Predictions.Convert.TranslateText.Result(
            text: translatedText,
            targetLanguage: targetLanguage ?? finalTargetLanguage
        )

        return translateTextResult
    }
}
