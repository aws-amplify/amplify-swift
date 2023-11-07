//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct ComprehendClient {
    struct Configuration {
        let region: String
        let credentialsProvider: CredentialsProvider
        let signingName = ""
    }

    let configuration: Configuration

    func detectDominantLanguage(input: DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutputResponse {
        fatalError()
    }

    func detectSyntax(input: DetectSyntaxInput) async throws -> DetectSyntaxOutputResponse {
        fatalError()
    }

    func detectSentiment(input: DetectSentimentInput) async throws -> DetectSentimentOutputResponse {
        fatalError()
    }

    func detectKeyPhrases(input: DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutputResponse {
        fatalError()
    }

    func detectEntities(input: DetectEntitiesInput) async throws -> DetectEntitiesOutputResponse {
        fatalError()
    }
}
