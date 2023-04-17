//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Speech

class CoreMLSpeechAdapter: CoreMLSpeechBehavior {
    func getTranscription(_ audioData: URL) async throws -> Predictions.Convert.SpeechToText.Result? {
        let request = SFSpeechURLRecognitionRequest(url: audioData)
        request.requiresOnDeviceRecognition = true
        let recognizer = SFSpeechRecognizer()

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SFSpeechRecognitionResult, Error>) in
            recognizer?.recognitionTask(
                with: request,
                resultHandler: { result, _ in
                    guard let result = result else {
                        continuation.resume(with: .failure(SomeError()))
                        return
                    }
                    continuation.resume(with: .success(result))
                })
        }

        if result.isFinal {
            let speechToTextResult = Predictions.Convert.SpeechToText.Result(transcription: result.bestTranscription.formattedString)
            return speechToTextResult
        }
        throw SomeError()
    }
}
