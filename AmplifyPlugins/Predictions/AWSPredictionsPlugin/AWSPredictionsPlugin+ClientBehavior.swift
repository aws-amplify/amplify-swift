//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
                        listener: PredictionsTranslateTextOperation.ResultListener? = nil)
        -> PredictionsTranslateTextOperation {

            let request = PredictionsTranslateTextRequest(textToTranslate: textToTranslate,
                                                          targetLanguage: targetLanguage,
                                                          language: language,
                                                          options: options ?? PredictionsTranslateTextRequest.Options())
            let convertOperation = AWSTranslateOperation(request,
                                                         predictionsService: predictionsService,
                                                         resultListener: listener)
            queue.addOperation(convertOperation)
            return convertOperation
    }

    public func convert(textToSpeech: String,
                        options: PredictionsTextToSpeechRequest.Options?,
                        listener: PredictionsTextToSpeechOperation.ResultListener? = nil)
        -> PredictionsTextToSpeechOperation {
            let request = PredictionsTextToSpeechRequest(
                textToSpeech: textToSpeech,
                options: options ?? PredictionsTextToSpeechRequest.Options())

            let convertOperation = AWSPollyOperation(request,
                                                     predictionsService: predictionsService,
                                                     resultListener: listener)

            queue.addOperation(convertOperation)
            return convertOperation

    }

    public func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options?,
        listener: PredictionsSpeechToTextOperation.ResultListener?
    ) -> PredictionsSpeechToTextOperation {
        let request = PredictionsSpeechToTextRequest(speechToText: speechToText,
                                                     options: options ?? PredictionsSpeechToTextRequest.Options())

        let multiService = TranscribeMultiService(coreMLService: coreMLService, predictionsService: predictionsService)

        // only one transcription request can be sent at a time otherwise you receive an error
        let requestInProcess = queue.operations.contains(where: { $0 is AWSTranscribeOperation})

        let operation = AWSTranscribeOperation(request: request,
                                               multiService: multiService,
                                               requestInProcess: requestInProcess,
                                               resultListener: listener)
        queue.addOperation(operation)
        return operation

    }

    public func identify(type: IdentifyAction,
                         image: URL,
                         options: PredictionsIdentifyRequest.Options?,
                         listener: PredictionsIdentifyOperation.ResultListener? = nil) -> PredictionsIdentifyOperation {
        let options = options

        let request = PredictionsIdentifyRequest(image: image,
                                                 identifyType: type,
                                                 options: options ?? PredictionsIdentifyRequest.Options())
        let multiService = IdentifyMultiService(coreMLService: coreMLService,
                                                predictionsService: predictionsService)
        let operation = IdentifyOperation(request: request,
                                          multiService: multiService,
                                          resultListener: listener)

        queue.addOperation(operation)
        return operation

    }

    /// Interprets the input text and detects sentiment, language, syntax, and key phrases
    ///
    /// - Parameter text: input text
    /// - Parameter options: Option for the plugin
    /// - Parameter resultListener: Listener to which events are send
    public func interpret(text: String,
                          options: PredictionsInterpretRequest.Options?,
                          listener: PredictionsInterpretOperation.ResultListener?) -> PredictionsInterpretOperation {

        let request = PredictionsInterpretRequest(textToInterpret: text,
                                                  options: options ?? PredictionsInterpretRequest.Options())
        let multiService = InterpretTextMultiService(coreMLService: coreMLService,
                                                     predictionsService: predictionsService)
        let operation = InterpretTextOperation(request,
                                               multiService: multiService,
                                               resultListener: listener)
        queue.addOperation(operation)
        return operation
    }
}
