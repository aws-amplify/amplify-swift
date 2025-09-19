//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Identify {
    enum DocumentText {}
}

public extension Predictions.Identify.Request where Output == Predictions.Identify.DocumentText.Result {
    static func textInDocument(textFormatType: Predictions.TextFormatType) -> Self {
        .init(kind: .detectTextInDocument(textFormatType, .lift))
    }
}
