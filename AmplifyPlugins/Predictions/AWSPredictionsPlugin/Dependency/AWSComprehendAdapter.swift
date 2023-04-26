//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSComprehend

class AWSComprehendAdapter: AWSComprehendBehavior {
    let awsComprehend: ComprehendClient

    init(_ awsComprehend: ComprehendClient) {
        self.awsComprehend = awsComprehend
    }

    func detectSentiment(
        request: DetectSentimentInput
    ) async throws -> DetectSentimentOutputResponse {
        try await awsComprehend.detectSentiment(input: request)
    }

    func detectEntities(
        request: DetectEntitiesInput
    ) async throws -> DetectEntitiesOutputResponse {
        try await awsComprehend.detectEntities(input: request)
    }

    func detectLanguage(
        request: DetectDominantLanguageInput
    ) async throws -> DetectDominantLanguageOutputResponse {
        try await awsComprehend.detectDominantLanguage(input: request)
    }

    func detectSyntax(
        request: DetectSyntaxInput
    ) async throws -> DetectSyntaxOutputResponse {
        try await awsComprehend.detectSyntax(input: request)
    }

    func detectKeyPhrases(
        request: DetectKeyPhrasesInput
    ) async throws -> DetectKeyPhrasesOutputResponse {
        try await awsComprehend.detectKeyPhrases(input: request)
    }

    func getComprehend() -> ComprehendClient {
        return awsComprehend
    }
}
