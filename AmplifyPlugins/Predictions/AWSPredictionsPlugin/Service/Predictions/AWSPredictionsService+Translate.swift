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
    ) async throws -> TranslateTextResult {

        guard let sourceLanguage = language ?? predictionsConfig.convert.translateText?.sourceLanguage else {
            throw PredictionsError.configuration(
                AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                nil
            )
        }
        guard let finalTargetLanguage = targetLanguage ?? predictionsConfig.convert.translateText?.targetLanguage else {
            throw PredictionsError.configuration(
                AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
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
        let translateTextResult = TranslateTextResult(
            text: translatedText,
            targetLanguage: targetLanguage ?? finalTargetLanguage
        )

        return translateTextResult
    }
}
