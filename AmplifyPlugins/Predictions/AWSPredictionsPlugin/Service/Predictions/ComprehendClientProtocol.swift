//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend

public protocol ComprehendClientProtocol {

    func detectDominantLanguage(input: DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutput

    func detectSyntax(input: DetectSyntaxInput) async throws -> DetectSyntaxOutput

    func detectKeyPhrases(input: DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutput

    func detectSentiment(input: DetectSentimentInput) async throws -> DetectSentimentOutput

    func detectEntities(input: DetectEntitiesInput) async throws -> DetectEntitiesOutput
}

extension ComprehendClient: ComprehendClientProtocol { }
