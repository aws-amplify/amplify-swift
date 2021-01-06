//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSComprehend

class AWSComprehendAdapter: AWSComprehendBehavior {

    let awsComprehend: AWSComprehend

    init(_ awsComprehend: AWSComprehend) {
        self.awsComprehend = awsComprehend
    }

    func detectSentiment(request: AWSComprehendDetectSentimentRequest) ->
        AWSTask<AWSComprehendDetectSentimentResponse> {
            return awsComprehend.detectSentiment(request)
    }

    func detectEntities(request: AWSComprehendDetectEntitiesRequest) ->
        AWSTask<AWSComprehendDetectEntitiesResponse> {
            return awsComprehend.detectEntities(request)
    }

    func detectLanguage(request: AWSComprehendDetectDominantLanguageRequest) ->
        AWSTask<AWSComprehendDetectDominantLanguageResponse> {
            return awsComprehend.detectDominantLanguage(request)
    }

    func detectSyntax(request: AWSComprehendDetectSyntaxRequest) ->
        AWSTask<AWSComprehendDetectSyntaxResponse> {
            return awsComprehend.detectSyntax(request)
    }

    func detectKeyPhrases(request: AWSComprehendDetectKeyPhrasesRequest) ->
        AWSTask<AWSComprehendDetectKeyPhrasesResponse> {
            return awsComprehend.detectKeyPhrases(request)
    }

    func getComprehend() -> AWSComprehend {
        return awsComprehend
    }
}
