//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Convert {
    enum SpeechToText {}
}

public extension Predictions.Convert.Request where
Input == URL,
Options == Predictions.Convert.SpeechToText.Options,
Output == AsyncThrowingStream<Predictions.Convert.SpeechToText.Result, Error> {

    static func speechToText(url: URL) -> Self {
        .init(input: url, kind: .speechToText(.lift))
    }
}
