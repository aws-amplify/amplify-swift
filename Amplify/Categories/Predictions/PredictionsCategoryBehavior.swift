//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Predictions category that clients will use
public protocol PredictionsCategoryBehavior {

    /// Translate the text to the language specified.
    /// - Parameter textToTranslate: The text to translate
    /// - Parameter language: The language of the text given
    /// - Parameter targetLanguage: The language to which the text should be translated
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    @discardableResult
    func convert(textToTranslate: String,
                 language: LanguageType?,
                 targetLanguage: LanguageType?,
                 options: PredictionsTranslateTextRequest.Options?,
                 listener: PredictionsTranslateTextOperation.ResultListener?) -> PredictionsTranslateTextOperation

    /// Synthesize the text to audio
    /// - Parameter textToSpeech: The text to be synthesized to audio
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    @discardableResult
    func convert(textToSpeech: String,
                 options: PredictionsTextToSpeechRequest.Options?,
                 listener: PredictionsTextToSpeechOperation.ResultListener?) -> PredictionsTextToSpeechOperation

    /// Transcribe audio to text
    /// - Parameter speechToText: The url of the audio to be transcribed
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    @discardableResult
    func convert(speechToText: URL,
                 options: PredictionsSpeechToTextRequest.Options?,
                 listener: PredictionsSpeechToTextOperation.ResultListener?) -> PredictionsSpeechToTextOperation

    /// Detect contents of an image based on `IdentifyAction`
    /// - Parameter type: The type of image detection you want to perform
    /// - Parameter image: The image you are sending
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    @discardableResult
    func identify(type: IdentifyAction,
                  image: URL,
                  options: PredictionsIdentifyRequest.Options?,
                  listener: PredictionsIdentifyOperation.ResultListener?) -> PredictionsIdentifyOperation

    /// Interpret the text and return sentiment analysis, entity detection, language detection,
    /// syntax detection, key phrases detection
    /// - Parameter text: Text to interpret
    /// - Parameter options:Parameters to specific plugin behavior
    /// - Parameter options:Parameters to specific plugin behavior
    @discardableResult
    func interpret(text: String,
                   options: PredictionsInterpretRequest.Options?,
                   listener: PredictionsInterpretOperation.ResultListener?) -> PredictionsInterpretOperation
}
