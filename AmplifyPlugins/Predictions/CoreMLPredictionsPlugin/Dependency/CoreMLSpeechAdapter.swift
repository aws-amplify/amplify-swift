//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Speech

class CoreMLSpeechAdapter: CoreMLSpeechBehavior {

    func getTranscription(_ audioData: URL, callback: @escaping (SpeechToTextResult?) -> Void) {
        let request = SFSpeechURLRecognitionRequest(url: audioData)
        request.requiresOnDeviceRecognition = true
        let recognizer = SFSpeechRecognizer()
        recognizer?.recognitionTask(with: request) { result, _ in
            guard let result = result else {
                callback(nil)
                return
            }

            if result.isFinal {
                let speechToTextResult = SpeechToTextResult(transcription: result.bestTranscription.formattedString)
                callback(speechToTextResult)
            }
        }
    }
}
