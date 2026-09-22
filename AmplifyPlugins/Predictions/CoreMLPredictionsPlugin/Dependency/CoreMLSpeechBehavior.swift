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

/// The part of `SFSpeechRecognitionResult` that callers actually use.
///
/// `SFSpeechRecognitionResult` is a non-`Sendable` Apple class, so returning one across an async
/// boundary is an error in the Swift 6 language mode. Carrying just these two values keeps the
/// Apple type inside the recognition callback that produced it.
struct CoreMLSpeechTranscription: Sendable {
    let formattedString: String
    let isFinal: Bool
}

protocol CoreMLSpeechBehavior: AnyObject, Sendable {
    func getTranscription(_ audioData: URL) async throws -> CoreMLSpeechTranscription
}
#endif
