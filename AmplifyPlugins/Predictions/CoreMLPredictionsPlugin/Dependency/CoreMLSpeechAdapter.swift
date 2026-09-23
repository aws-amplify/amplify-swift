//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// See CoreMLSpeechBehavior for why tvOS is excluded here.
#if canImport(Speech) && !os(tvOS)
import Amplify
import Speech

final class CoreMLSpeechAdapter: CoreMLSpeechBehavior {
    // Returns `CoreMLSpeechTranscription` rather than the `SFSpeechRecognitionResult` itself:
    // that type is not `Sendable`, so resuming a continuation with one is an error in the Swift 6
    // language mode. Reading the two fields callers need inside the result handler keeps the
    // non-Sendable Apple type from crossing the boundary at all.
    func getTranscription(_ audioData: URL) async throws -> CoreMLSpeechTranscription {
        let request = SFSpeechURLRecognitionRequest(url: audioData)
        request.requiresOnDeviceRecognition = true
        guard let recognizer = SFSpeechRecognizer() else {
            throw PredictionsError.client(
                .init(
                    description: "CoreML Service is not configured",
                    recoverySuggestion: "Ensure that dictation is enabled on your device."
                )
            )
        }

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CoreMLSpeechTranscription, Error>) in
            recognizer.recognitionTask(
                with: request,
                resultHandler: { result, error in
                    if let error {
                        continuation.resume(with: .failure(error))
                        return
                    }

                    guard let result else {
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

                    continuation.resume(with: .success(.init(
                        formattedString: result.bestTranscription.formattedString,
                        isFinal: result.isFinal
                    )))

                }
            )
        }
        return result
    }
}
#endif
