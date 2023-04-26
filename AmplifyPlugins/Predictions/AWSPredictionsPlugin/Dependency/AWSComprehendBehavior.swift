//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSComprehend

protocol AWSComprehendBehavior {
    func detectSentiment(
        request: DetectSentimentInput
    ) async throws -> DetectSentimentOutputResponse

    func detectEntities(
        request: DetectEntitiesInput
    ) async throws -> DetectEntitiesOutputResponse

    func detectLanguage(
        request: DetectDominantLanguageInput
    ) async throws -> DetectDominantLanguageOutputResponse

    func detectSyntax(
        request: DetectSyntaxInput
    ) async throws -> DetectSyntaxOutputResponse

    func detectKeyPhrases(
        request: DetectKeyPhrasesInput
    ) async throws -> DetectKeyPhrasesOutputResponse

    func getComprehend() -> ComprehendClient
}
