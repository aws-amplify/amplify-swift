//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Speech

class CoreMLSpeechAdapter: CoreMLSpeechBehavior {

    func getTranscription(_ audioData: URL) -> SpeechToTextResult? {
        let request = SFSpeechURLRecognitionRequest(url: audioData)
        var transcriptions = [String]()
        SFSpeechRecognizer()?.recognitionTask(with: request) { result, _ in
            if let transcriptionResults = result?.transcriptions {
                for transcriptionResult in transcriptionResults {
                    transcriptions.append(transcriptionResult.formattedString)
                }
          }
        }
        return SpeechToTextResult(transcriptions: transcriptions)

    }
}
