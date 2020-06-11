//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import UIKit
import Foundation

class MockPredictionsCategoryPlugin: MessageReporter, PredictionsCategoryPlugin {
    var responders = MockPredictionsCategoryPlugin.Responders()

    func configure(using configuration: Any?) throws {
        notify()
    }

    func convert(speechToText url: URL,
                 options: PredictionsSpeechToTextRequest.Options?,
                 listener: PredictionsSpeechToTextOperation.ResultListener?) -> PredictionsSpeechToTextOperation {
        notify("speechToText")

        if let responder = responders.convertSpeechToText {
            let result = responder(url, options)
            listener?(result)
        }

        let request = PredictionsSpeechToTextRequest(speechToText: url,
                                                     options: options ?? PredictionsSpeechToTextRequest.Options())
        return MockPredictionsSpeechToTextOperation(request: request)

    }

    func convert(textToSpeech: String,
                 options: PredictionsTextToSpeechRequest.Options?,
                 listener: PredictionsTextToSpeechOperation.ResultListener?) -> PredictionsTextToSpeechOperation {
        notify("textToSpeech")

        if let responder = responders.convertTextToSpeech {
            let result = responder(textToSpeech, options)
            listener?(result)
        }

        let request = PredictionsTextToSpeechRequest(textToSpeech: textToSpeech,
                                                     options: options ?? PredictionsTextToSpeechRequest.Options())
        return MockPredictionsTextToSpeechOperation(request: request)
    }

    func convert(textToTranslate: String,
                 language: LanguageType?,
                 targetLanguage: LanguageType?,
                 options: PredictionsTranslateTextRequest.Options?,
                 listener: PredictionsTranslateTextOperation.ResultListener?) -> PredictionsTranslateTextOperation {
        notify("textToTranslate")

        if let responder = responders.convertTextToTranslate {
            let result = responder(textToTranslate, language, targetLanguage, options)
            listener?(result)
        }

        let request = PredictionsTranslateTextRequest(textToTranslate: textToTranslate,
                                                      targetLanguage: targetLanguage ?? .italian,
                                                      language: language ?? .english,
                                                      options: options ?? PredictionsTranslateTextRequest.Options())
        return MockPredictionsTranslateTextOperation(request: request)

    }

    func identify(type: IdentifyAction,
                  image: URL,
                  options: PredictionsIdentifyRequest.Options?,
                  listener: PredictionsIdentifyOperation.ResultListener?)
        -> PredictionsIdentifyOperation {
            notify("identifyLabels")

            if let responder = responders.identify {
                let result = responder(type, image, options)
                listener?(result)
            }

            let request = PredictionsIdentifyRequest(image: image,
                                                     identifyType: type,
                                                     options: options ?? PredictionsIdentifyRequest.Options())
            return MockPredictionsIdentifyOperation(request: request)
    }

    func interpret(text: String,
                   options: PredictionsInterpretRequest.Options?,
                   listener: PredictionsInterpretOperation.ResultListener?) -> PredictionsInterpretOperation {
        notify("interpret")

        if let responder = responders.interpret {
            let result = responder(text, options)
            listener?(result)
        }

        let request = PredictionsInterpretRequest(textToInterpret: text,
                                                  options: options ?? PredictionsInterpretRequest.Options())
        return MockPredictionsInterpretOperation(request: request)
    }

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        onComplete()
    }

    var key: String {
        return "MockPredictionsCategoryPlugin"
    }
}

class MockSecondPredictionsCategoryPlugin: MockPredictionsCategoryPlugin {
    override var key: String {
        return "MockSecondPredictionsCategoryPlugin"
    }
}

class MockPredictionsTranslateTextOperation: AmplifyOperation<
    PredictionsTranslateTextRequest,
    TranslateTextResult,
    PredictionsError
>, PredictionsTranslateTextOperation {

    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.translate,
                   request: request)
    }

}

class MockPredictionsSpeechToTextOperation: AmplifyOperation<
    PredictionsSpeechToTextRequest,
    SpeechToTextResult,
    PredictionsError
>, PredictionsSpeechToTextOperation {

    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.speechToText,
                   request: request)
    }

}

class MockPredictionsTextToSpeechOperation: AmplifyOperation<
    PredictionsTextToSpeechRequest,
    TextToSpeechResult,
    PredictionsError
>, PredictionsTextToSpeechOperation {

    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.textToSpeech,
                   request: request)
    }

}

class MockPredictionsIdentifyOperation: AmplifyOperation<
    PredictionsIdentifyRequest,
    IdentifyResult,
    PredictionsError
>, PredictionsIdentifyOperation {

    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.identifyLabels,
                   request: request)
    }

}

class MockPredictionsInterpretOperation: AmplifyOperation<
    PredictionsInterpretRequest,
    InterpretResult,
    PredictionsError
>, PredictionsInterpretOperation {

    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.interpret,
                   request: request)
    }

}
