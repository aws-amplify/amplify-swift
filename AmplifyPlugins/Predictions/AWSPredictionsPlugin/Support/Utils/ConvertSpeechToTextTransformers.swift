//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// TODO: Transcribe

//import AWSTranscribeStreaming
//import Amplify
//
//class ConvertSpeechToTextTransformers {
//    static func processTranscription(
//        _ transcribeResultBlocks: [AWSTranscribeStreamingResult]
//    ) -> SpeechToTextResult? {
//        var transcription = ""
//
//        guard let firstResult = transcribeResultBlocks.first,
//            let isPartial = firstResult.isPartial as? Bool else {
//                return nil
//        }
//
//        guard !isPartial else {
//            return nil
//        }
//
//        transcription = firstResult.alternatives?.first?.transcript ?? ""
//
//        return SpeechToTextResult(transcription: transcription)
//    }
//}
