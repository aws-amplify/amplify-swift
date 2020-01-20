//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct TextToSpeechResult: ConvertResult {
     public let audioData: Data

    public init(audioData: Data) {
        self.audioData = audioData
    }
}
