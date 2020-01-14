//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class PredictionsSpeechToTextRequest: PredictionsConvertRequest {
    
    /// The text to synthesize to speech
    public let speechToText: URL

    public init(speechToText: URL,
                options: Options) {
        self.speechToText = speechToText
        super.init(type: .speechToText, options: options)
    }
}

