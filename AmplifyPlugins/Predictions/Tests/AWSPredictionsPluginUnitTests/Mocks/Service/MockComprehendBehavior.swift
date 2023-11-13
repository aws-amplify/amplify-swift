//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPredictionsPlugin

//class MockComprehendBehavior: ComprehendClient {
//    var sentimentResponse: ((DetectSentimentInput) async throws -> DetectSentimentOutputResponse)? = nil
//    var entitiesResponse: ((DetectEntitiesInput) async throws -> DetectEntitiesOutputResponse)? = nil
//    var languageResponse: ((DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutputResponse)? = nil
//    var syntaxResponse: ((DetectSyntaxInput) async throws -> DetectSyntaxOutputResponse)? = nil
//    var keyPhrasesResponse: ((DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutputResponse)? = nil
//
//    func detectSentiment(input: DetectSentimentInput) async throws -> DetectSentimentOutputResponse {
//        guard let sentimentResponse else { throw MockBehaviorDefaultError() }
//        return try await sentimentResponse(input)
//    }
//
//    func detectEntities(input: DetectEntitiesInput) async throws -> DetectEntitiesOutputResponse {
//        guard let entitiesResponse else { throw MockBehaviorDefaultError() }
//        return try await entitiesResponse(input)
//    }
//
//    func detectDominantLanguage(input: DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutputResponse {
//        guard let languageResponse else { throw MockBehaviorDefaultError() }
//        return try await languageResponse(input)
//    }
//
//    func detectSyntax(input: DetectSyntaxInput) async throws -> DetectSyntaxOutputResponse {
//        guard let syntaxResponse else { throw MockBehaviorDefaultError() }
//        return try await syntaxResponse(input)
//    }
//
//    func detectKeyPhrases(input: DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutputResponse {
//        guard let keyPhrasesResponse else { throw MockBehaviorDefaultError() }
//        return try await keyPhrasesResponse(input)
//    }
//
//    func getComprehend() -> ComprehendClient {
//        try! ComprehendClient(region: "us-east-1")
//    }
//}

