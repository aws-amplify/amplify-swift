//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct InterpretResult {

    var keyPhrases: [KeyPhrase]?
    var sentiment: Sentiment?
    var entities: [EntityDetectionResult]?
    var language: LanguageDetectionResult?
    var syntax: [SyntaxToken]?
}
