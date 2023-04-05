//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranslate

extension AWSPredictionsService: AWSTranslateServiceBehavior {

    func translateText(text: String,
                       language: LanguageType?,
                       targetLanguage: LanguageType?,
                       onEvent: @escaping AWSPredictionsService.TranslateTextServiceEventHandler) {

        guard let sourceLanguage = language ?? predictionsConfig.convert.translateText?.sourceLanguage else {
            onEvent(.failed(.configuration(AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                                           AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                                           nil)))
            return
        }
        guard let finalTargetLanguage = targetLanguage ?? predictionsConfig.convert.translateText?.targetLanguage else {
            onEvent(.failed(.configuration(AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                                           AWSTranslateErrorMessage.sourceLanguageNotProvided.errorDescription,
                                           nil)))
            return
        }

        let request: AWSTranslateTranslateTextRequest = AWSTranslateTranslateTextRequest()
        request.sourceLanguageCode = sourceLanguage.rawValue
        request.targetLanguageCode = finalTargetLanguage.rawValue
        request.text = text
        awsTranslate.translateText(request: request).continueWith { (task) -> Any? in

            guard task.error == nil else {

                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                onEvent(.failed(
                    .network(predictionsErrorString.errorDescription,
                             predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknown("No result was found. An unknown error occurred.", "Please try again.")))
                return nil
            }

            guard let translatedText = result.translatedText else {
                let noResult = AWSTranslateErrorMessage.noTranslateTextResult
                onEvent(.failed(
                    .network(noResult.errorDescription, noResult.recoverySuggestion)
                    )
                )
                return nil
            }

            let targetLanguage = LanguageType(rawValue: result.targetLanguageCode ?? "")
            let translateTextResult = TranslateTextResult(
                text: translatedText,
                targetLanguage: targetLanguage ?? finalTargetLanguage)

            onEvent(.completed(translateTextResult))
            return nil
        }
    }
}
