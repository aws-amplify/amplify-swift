//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSPredictionsService: AWSTranslateServiceBehavior {
    func translateText(
        text: String,
        language: Predictions.Language?,
        targetLanguage: Predictions.Language?
    ) async throws -> Predictions.Convert.TranslateText.Result {
        // prefer passed in language. If it's not there, try to grab it from the config,
        // If that doesn't exist, we can't progress any further and throw an error
        guard let sourceLanguage = language ?? predictionsConfig.convert.translateText?.sourceLanguage else {
            throw PredictionsError.client(.missingSourceLanguage)
        }

        // prefer passed in language. If it's not there, try to grab it from the config,
        // If that doesn't exist, we can't progress any further and throw an error
        guard let targetLanguage = targetLanguage ?? predictionsConfig.convert.translateText?.targetLanguage else {
            throw PredictionsError.client(.missingTargetLanguage)
        }

        let request = TranslateTextInput(
            sourceLanguageCode: sourceLanguage.code,
            targetLanguageCode: targetLanguage.code,
            text: text
        )

        let textTranslateResult: TranslateTextOutputResponse
        do {
            textTranslateResult = try await awsTranslate.translateText(input: request)
        } catch let error as PredictionsErrorConvertible {
            throw error.predictionsError
        } catch {
            throw PredictionsError.unexpectedServiceErrorType(error)
        }

        // TODO: made this non-optional based on docs - double check if it causes issues
        let translatedText = textTranslateResult.translatedText

        let translateTextResult = Predictions.Convert.TranslateText.Result(
            text: translatedText,
            targetLanguage: targetLanguage
        )

        return translateTextResult
    }
}
