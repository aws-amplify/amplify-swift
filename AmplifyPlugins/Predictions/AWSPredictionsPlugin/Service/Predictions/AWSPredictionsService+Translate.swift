//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranslate

extension AWSPredictionsService: AWSTranslateServiceBehavior {

    func translateText(text: String,
                       language: LanguageType,
                       targetLanguage: LanguageType,
                       onEvent: @escaping AWSPredictionsService.TranslateTextServiceEventHandler) {
        let request: AWSTranslateTranslateTextRequest = AWSTranslateTranslateTextRequest()
        request.sourceLanguageCode = language.rawValue
        request.targetLanguageCode = targetLanguage.rawValue
        request.text = text
        awsTranslate.translateText(request: request).continueWith { (task) -> Any? in

            guard task.error == nil else {

                onEvent(.failed(.networkError(task.error!.localizedDescription, task.error!.localizedDescription)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknownError("No result was found. An unknown error occurred.", "Please try again.")))
                return nil
            }

            guard let translatedText = result.translatedText else {
                onEvent(.failed(
                    .networkError("No result was found.",
                                  "Please make sure a text string was sent over and that the target language was different from the language sent.")))
                return nil
            }

            let translateTextResult = TranslateTextResult(
                text: translatedText,
                targetLanguage: .italian)

            onEvent(.completed(translateTextResult))
            return nil
        }
    }
}
