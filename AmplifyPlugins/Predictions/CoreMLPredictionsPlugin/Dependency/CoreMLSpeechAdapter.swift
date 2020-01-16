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
        request.requiresOnDeviceRecognition = true
        var transcriptions = [String]()
        let recognizer = SFSpeechRecognizer()
        let semaphore = DispatchSemaphore(value: 0)
        recognizer?.recognitionTask(with: request) { result, _ in
            guard let result = result else {
                print("There was an error transcribing that file")
                return
            }
            
            if result.isFinal {
                transcriptions.append(result.bestTranscription.formattedString)
                semaphore.signal()
            }
        }
        semaphore.wait()
        return SpeechToTextResult(transcriptions: transcriptions)
        
    }
}
