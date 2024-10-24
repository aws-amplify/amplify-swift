//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Convert {
    enum TextToSpeech {}
}

public extension Predictions.Convert.Request where
Input == String,
Options == Predictions.Convert.TextToSpeech.Options,
Output == Predictions.Convert.TextToSpeech.Result {

    static func textToSpeech(_ text: String) -> Self {
        .init(input: text, kind: .textToSpeech(.lift))
    }
}
