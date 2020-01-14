//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class PredictionsTextToSpeechRequest: PredictionsConvertRequest {
    
    /// The text to synthesize to speech
    public let textToSpeech: String

    public init(textToSpeech: String,
                options: Options) {
        self.textToSpeech = textToSpeech
        super.init(type: .textToSpeech, options: options)
    }
}

