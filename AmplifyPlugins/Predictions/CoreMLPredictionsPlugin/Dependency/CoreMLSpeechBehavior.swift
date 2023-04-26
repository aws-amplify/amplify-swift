//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Speech

protocol CoreMLSpeechBehavior: AnyObject {
    func getTranscription(_ audioData: URL) async throws -> SFSpeechRecognitionResult
}
