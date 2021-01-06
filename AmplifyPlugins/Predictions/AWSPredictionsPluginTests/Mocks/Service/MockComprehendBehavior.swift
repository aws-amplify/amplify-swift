//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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

    func detectSentiment(request: AWSComprehendDetectSentimentRequest)
        -> AWSTask<AWSComprehendDetectSentimentResponse> {
        guard let finalError = error else {
            return AWSTask(result: sentimentResponse)
        }
        return AWSTask(error: finalError)
    }

    func detectEntities(request: AWSComprehendDetectEntitiesRequest)
        -> AWSTask<AWSComprehendDetectEntitiesResponse> {
        guard let finalError = error else {
            return AWSTask(result: entitiesResponse)
        }
        return AWSTask(error: finalError)
    }

    func detectLanguage(request: AWSComprehendDetectDominantLanguageRequest)
        -> AWSTask<AWSComprehendDetectDominantLanguageResponse> {
        guard let finalError = error else {
            return AWSTask(result: languageResponse)
        }
        return AWSTask(error: finalError)
    }

    func detectSyntax(request: AWSComprehendDetectSyntaxRequest)
        -> AWSTask<AWSComprehendDetectSyntaxResponse> {
        guard let finalError = error else {
            return AWSTask(result: syntaxResponse)
        }
        return AWSTask(error: finalError)
    }

    func detectKeyPhrases(request: AWSComprehendDetectKeyPhrasesRequest)
        -> AWSTask<AWSComprehendDetectKeyPhrasesResponse> {
        guard let finalError = error else {
            return AWSTask(result: keyPhrasesResponse)
        }
        return AWSTask(error: finalError)
    }

    func getComprehend() -> AWSComprehend {
        return AWSComprehend()
    }

    public func setResult(sentimentResponse: AWSComprehendDetectSentimentResponse? = nil,
                          entitiesResponse: AWSComprehendDetectEntitiesResponse? = nil,
                          languageResponse: AWSComprehendDetectDominantLanguageResponse? = nil,
                          syntaxResponse: AWSComprehendDetectSyntaxResponse? = nil,
                          keyPhrasesResponse: AWSComprehendDetectKeyPhrasesResponse? = nil) {
        self.sentimentResponse = sentimentResponse
        self.entitiesResponse = entitiesResponse
        self.languageResponse = languageResponse
        self.syntaxResponse = syntaxResponse
        self.keyPhrasesResponse = keyPhrasesResponse
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
