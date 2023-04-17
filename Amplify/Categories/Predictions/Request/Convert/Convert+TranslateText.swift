//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Predictions.Convert {
    public enum TranslateText {}
}

extension Predictions.Convert.Request where
Input == (String, LanguageType?, LanguageType?),
Options == Predictions.Convert.TranslateText.Options,
Output == Predictions.Convert.TranslateText.Result {

    public static func textToTranslate(
        _ text: String,
        from: LanguageType? = nil,
        to: LanguageType? = nil
    ) -> Self {
        .init(
            input: (text, from, to),
            kind: .textToTranslate(.lift)
        )
    }
}
