//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Speech

class CoreMLSpeechAdapter: CoreMLSpeechBehavior {
    func getTranscription(_ audioData: URL) async throws -> SFSpeechRecognitionResult {
        let request = SFSpeechURLRecognitionRequest(url: audioData)
        request.requiresOnDeviceRecognition = true
        let recognizer = SFSpeechRecognizer()

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SFSpeechRecognitionResult, Error>) in
            recognizer?.recognitionTask(
                with: request,
                resultHandler: { result, _ in
                    guard let result = result else {
                        continuation.resume(with: .failure(
                            PredictionsError.client(
                                .init(
                                    description: "CoreML Service is not configured",
                                    recoverySuggestion: "Ensure that your configuration file is correct."
                                )
                            )
                        ))
                        return
                    }


                    continuation.resume(with: .success(result))

                }
            )
        }
        return result
    }
}
