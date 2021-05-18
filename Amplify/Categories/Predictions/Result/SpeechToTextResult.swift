//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SpeechToTextResult: ConvertResult {
    /// Resulting string from speech to text conversion
    public let transcription: String

    public init(transcription: String) {
        self.transcription = transcription
    }
}
