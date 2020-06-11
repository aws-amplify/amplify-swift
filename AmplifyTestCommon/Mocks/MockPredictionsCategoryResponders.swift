//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockPredictionsCategoryPlugin {
    struct Responders {
        var convertSpeechToText: ConvertSpeechToTextResponder?
        var convertTextToSpeech: ConvertTextToSpeechResponder?
        var convertTextToTranslate: ConvertTextToTranslateResponder?
        var identify: IdentifyResponder?
        var interpret: InterpretResponder?
    }
}

typealias ConvertSpeechToTextResponder = (
    URL,
    PredictionsSpeechToTextRequest.Options?
) -> PredictionsSpeechToTextOperation.OperationResult

typealias ConvertTextToSpeechResponder = (
    String,
    PredictionsTextToSpeechRequest.Options?
) -> PredictionsTextToSpeechOperation.OperationResult

typealias ConvertTextToTranslateResponder = (
    String,
    LanguageType?,
    LanguageType?,
    PredictionsTranslateTextRequest.Options?
) -> PredictionsTranslateTextOperation.OperationResult

typealias IdentifyResponder = (
    IdentifyAction,
    URL,
    PredictionsIdentifyRequest.Options?
) -> PredictionsIdentifyOperation.OperationResult

typealias InterpretResponder = (
    String,
    PredictionsInterpretRequest.Options?
) -> PredictionsInterpretOperation.OperationResult
