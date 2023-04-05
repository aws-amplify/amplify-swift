//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSComprehend

protocol AWSComprehendBehavior {

    func detectSentiment(request: AWSComprehendDetectSentimentRequest) ->
        AWSTask<AWSComprehendDetectSentimentResponse>

    func detectEntities(request: AWSComprehendDetectEntitiesRequest) ->
        AWSTask<AWSComprehendDetectEntitiesResponse>

    func detectLanguage(request: AWSComprehendDetectDominantLanguageRequest) ->
        AWSTask<AWSComprehendDetectDominantLanguageResponse>

    func detectSyntax(request: AWSComprehendDetectSyntaxRequest) ->
        AWSTask<AWSComprehendDetectSyntaxResponse>

    func detectKeyPhrases(request: AWSComprehendDetectKeyPhrasesRequest) ->
        AWSTask<AWSComprehendDetectKeyPhrasesResponse>

    func getComprehend() -> AWSComprehend

}
