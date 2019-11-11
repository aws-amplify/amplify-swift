//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct InterpretResult {

    public var keyPhrases: [KeyPhrase]?
    public var sentiment: Sentiment?
    public var entities: [EntityDetectionResult]?
    public var language: LanguageDetectionResult?
    public var syntax: [SyntaxToken]?

    public  init() {

    }
}
