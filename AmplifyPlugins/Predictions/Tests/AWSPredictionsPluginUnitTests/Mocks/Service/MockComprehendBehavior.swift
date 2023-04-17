//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
@testable import AWSPredictionsPlugin

class MockComprehendBehavior: AWSComprehendBehavior {
    var sentimentResponse: ((DetectSentimentInput) async throws -> DetectSentimentOutputResponse)? = nil
    var entitiesResponse: ((DetectEntitiesInput) async throws -> DetectEntitiesOutputResponse)? = nil
    var languageResponse: ((DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutputResponse)? = nil
    var syntaxResponse: ((DetectSyntaxInput) async throws -> DetectSyntaxOutputResponse)? = nil
    var keyPhrasesResponse: ((DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutputResponse)? = nil

    func detectSentiment(request: DetectSentimentInput) async throws -> DetectSentimentOutputResponse {
        guard let sentimentResponse else { throw MockBehaviorDefaultError() }
        return try await sentimentResponse(request)
    }

    func detectEntities(request: DetectEntitiesInput) async throws -> DetectEntitiesOutputResponse {
        guard let entitiesResponse else { throw MockBehaviorDefaultError() }
        return try await entitiesResponse(request)
    }

    func detectLanguage(request: DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutputResponse {
        guard let languageResponse else { throw MockBehaviorDefaultError() }
        return try await languageResponse(request)
    }

    func detectSyntax(request: DetectSyntaxInput) async throws -> DetectSyntaxOutputResponse {
        guard let syntaxResponse else { throw MockBehaviorDefaultError() }
        return try await syntaxResponse(request)
    }

    func detectKeyPhrases(request: DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutputResponse {
        guard let keyPhrasesResponse else { throw MockBehaviorDefaultError() }
        return try await keyPhrasesResponse(request)
    }

    func getComprehend() -> ComprehendClient {
        try! ComprehendClient(region: "us-east-1")
    }
}
