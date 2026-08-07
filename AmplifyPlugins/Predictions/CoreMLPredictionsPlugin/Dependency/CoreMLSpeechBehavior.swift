//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// SFSpeechRecognitionResult is marked API_UNAVAILABLE(tvos). As of the Xcode 26
// SDKs the Speech module is importable on tvOS, so canImport(Speech) alone no
// longer excludes the platform.
#if canImport(Speech) && !os(tvOS)
import Amplify
import Foundation
import Speech

protocol CoreMLSpeechBehavior: AnyObject {
    func getTranscription(_ audioData: URL) async throws -> SFSpeechRecognitionResult
}
#endif
