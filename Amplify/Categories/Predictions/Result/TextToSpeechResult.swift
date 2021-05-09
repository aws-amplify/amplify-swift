//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct TextToSpeechResult: ConvertResult {

    /// <#Description#>
    public let audioData: Data

    /// <#Description#>
    /// - Parameter audioData: <#audioData description#>
    public init(audioData: Data) {
        self.audioData = audioData
    }
}
