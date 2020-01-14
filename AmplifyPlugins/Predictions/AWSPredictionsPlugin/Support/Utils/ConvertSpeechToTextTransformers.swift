//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranscribeStreaming
import Amplify

class ConvertSpeechToTextTransformers {
    static func processTranscription(_ transcribeResultBlocks: [AWSTranscribeStreamingResult]) -> SpeechToTextResult {
        var transcriptions = [String]()

        for transcribeResult in transcribeResultBlocks {
            if let alternatives = transcribeResult.alternatives {
                for alternative in alternatives {
                    if let transcript = alternative.transcript {
                    transcriptions.append(transcript)
                    }
                }
            }
        }

        return SpeechToTextResult(transcriptions: transcriptions)
    }
}
