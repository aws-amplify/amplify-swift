//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct TextractClient {
    struct Configuration {
        let region: String
        let credentialsProvider: CredentialsProvider
        let signingName = ""
    }

    let configuration: Configuration

    func detectDocumentText(input: DetectDocumentTextInput) async throws -> DetectDocumentTextOutputResponse {
        fatalError()
    }

    func analyzeDocument(input: AnalyzeDocumentInput) async throws -> AnalyzeDocumentOutputResponse {
        fatalError()
    }
}
