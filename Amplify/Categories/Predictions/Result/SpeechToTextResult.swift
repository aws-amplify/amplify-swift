//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct SpeechToTextResult: ConvertResult {

    /// <#Description#>
    public let transcription: String

    /// <#Description#>
    /// - Parameter transcription: <#transcription description#>
    public init(transcription: String) {
        self.transcription = transcription
    }
}
