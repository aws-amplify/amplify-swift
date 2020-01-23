//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SpeechToTextResult: ConvertResult {
     public let transcription: String

    public init(transcription: String) {
        self.transcription = transcription
    }
}
