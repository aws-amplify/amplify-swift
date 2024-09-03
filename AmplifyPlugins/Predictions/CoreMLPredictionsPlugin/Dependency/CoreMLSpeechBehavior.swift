//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech)
import Amplify
import Foundation
import Speech

protocol CoreMLSpeechBehavior: AnyObject {
    func getTranscription(_ audioData: URL) async throws -> SFSpeechRecognitionResult
}
#endif
