//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSPredictionsPlugin {

    public func convert(textToTranslate: String,
                        language: LanguageType?,
                        targetLanguage: LanguageType?,
                        options: PredictionsTranslateTextRequest.Options?,
                        listener: PredictionsTranslateTextOperation.EventListener? = nil)
        -> PredictionsTranslateTextOperation {

            let request = PredictionsTranslateTextRequest(textToTranslate: textToTranslate,
                                                          targetLanguage: targetLanguage,
                                                          language: language,
                                                          options: options ?? PredictionsTranslateTextRequest.Options())
            let convertOperation = AWSTranslateOperation(request,
                                                         predictionsService: predictionsService,
                                                         listener: listener)
            queue.addOperation(convertOperation)
            return convertOperation
    }

    public func convert(textToSpeech: String,
                        options: PredictionsTextToSpeechRequest.Options?,
                        listener: PredictionsTextToSpeechOperation.EventListener? = nil)
        -> PredictionsTextToSpeechOperation {
            let request = PredictionsTextToSpeechRequest(
                textToSpeech: textToSpeech,
                options: options ?? PredictionsTextToSpeechRequest.Options())

            let convertOperation = AWSPollyOperation(request,
                                                     predictionsService: predictionsService,
                                                     authService: authService,
                                                     listener: listener)

            queue.addOperation(convertOperation)
            return convertOperation

    }

    public func identify(type: IdentifyAction,
                         image: URL,
                         options: PredictionsIdentifyRequest.Options?,
                         listener: PredictionsIdentifyOperation.EventListener? = nil) -> PredictionsIdentifyOperation {
        let options = options

        let request = PredictionsIdentifyRequest(image: image,
                                                 identifyType: type,
                                                 options: options ?? PredictionsIdentifyRequest.Options())
        let multiService = IdentifyMultiService(coreMLService: coreMLService,
                                                predictionsService: predictionsService)
        let operation = IdentifyOperation(request: request,
                                          multiService: multiService,
                                          listener: listener)

        queue.addOperation(operation)
        return operation

    }

    /// Interprets the input text and detects sentiment, language, syntax, and key phrases
    ///
    /// - Parameter text: input text
    /// - Parameter options: Option for the plugin
    /// - Parameter listener: Listener to which events are send
    public func interpret(text: String,
                          options: PredictionsInterpretRequest.Options?,
                          listener: PredictionsInterpretOperation.EventListener?) -> PredictionsInterpretOperation {

        let request = PredictionsInterpretRequest(textToInterpret: text,
                                                  options: options ?? PredictionsInterpretRequest.Options())
        let multiService = InterpretTextMultiService(coreMLService: coreMLService,
                                                     predictionsService: predictionsService)
        let operation = InterpretTextOperation(request,
                                               multiService: multiService,
                                               listener: listener)
        queue.addOperation(operation)
        return operation
    }
}
