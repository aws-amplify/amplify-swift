//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol CoreMLPredictionBehavior: AnyObject {

    typealias InterpretTextEventHandler = (InterpretEvent) -> Void
    typealias InterpretEvent = PredictionsEvent<InterpretResult, PredictionsError>

    typealias IdentifyEventHandler = (IdentifyEvent) -> Void
    typealias IdentifyEvent = PredictionsEvent<IdentifyResult, PredictionsError>

    typealias TranscribeEventHandler = (TranscribeEvent) -> Void
    typealias TranscribeEvent = PredictionsEvent<SpeechToTextResult, PredictionsError>

    func comprehend(text: String,
                    onEvent: @escaping InterpretTextEventHandler)

    func identify(_ imageURL: URL,
                  type: IdentifyAction,
                  onEvent: @escaping IdentifyEventHandler)

    func transcribe(_ speechToText: URL,
                    onEvent: @escaping TranscribeEventHandler)

}
