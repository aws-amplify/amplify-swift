//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SpeechToTextResult: ConvertResult {
     public let text: String

    public init(text: String) {
        self.text = text
    }
}
