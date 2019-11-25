//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
@testable import AWSPredictionsPlugin

class MockComprehendBehavior: AWSComprehendBehavior {

    var sentimentResponse: AWSComprehendDetectSentimentResponse?
    var entitiesResponse: AWSComprehendDetectEntitiesResponse?
    var languageResponse: AWSComprehendDetectDominantLanguageResponse?
    var syntaxResponse: AWSComprehendDetectSyntaxResponse?
    var keyPhrasesResponse: AWSComprehendDetectKeyPhrasesResponse?

    var error: Error?

    func detectSentiment(request: AWSComprehendDetectSentimentRequest) -> AWSTask<AWSComprehendDetectSentimentResponse> {
        if let finalResult = sentimentResponse {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func detectEntities(request: AWSComprehendDetectEntitiesRequest) -> AWSTask<AWSComprehendDetectEntitiesResponse> {
        if let finalResult = entitiesResponse {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func detectLanguage(request: AWSComprehendDetectDominantLanguageRequest) -> AWSTask<AWSComprehendDetectDominantLanguageResponse> {
        if let finalResult = languageResponse {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func detectSyntax(request: AWSComprehendDetectSyntaxRequest) -> AWSTask<AWSComprehendDetectSyntaxResponse> {
        if let finalResult = syntaxResponse {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func detectKeyPhrases(request: AWSComprehendDetectKeyPhrasesRequest) -> AWSTask<AWSComprehendDetectKeyPhrasesResponse> {
        if let finalResult = keyPhrasesResponse {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func getComprehend() -> AWSComprehend {
        return AWSComprehend()
    }

    public func setSentimentResponse(result: AWSComprehendDetectSentimentResponse) {
        sentimentResponse = result
        error = nil
    }

    public func setEntitiesResponse(result: AWSComprehendDetectEntitiesResponse) {
        entitiesResponse = result
        error = nil
    }

    public func setLanguageResponse(result: AWSComprehendDetectDominantLanguageResponse) {
        languageResponse = result
        error = nil
    }

    public func setSyntaxResponse(result: AWSComprehendDetectSyntaxResponse) {
        syntaxResponse = result
        error = nil
    }

    public func setKeyPhrasesResponse(result: AWSComprehendDetectKeyPhrasesResponse) {
        keyPhrasesResponse = result
        error = nil
    }

    public func setError(error: Error) {
        sentimentResponse = nil
        entitiesResponse = nil
        languageResponse = nil
        syntaxResponse = nil
        keyPhrasesResponse = nil
        self.error = error
    }

}
