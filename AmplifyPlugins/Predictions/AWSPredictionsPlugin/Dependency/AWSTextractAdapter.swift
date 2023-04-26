//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTextract

class AWSTextractAdapter: AWSTextractBehavior {
    let awsTextract: TextractClient

    init(_ awsTextract: TextractClient) {
        self.awsTextract = awsTextract
    }

    func analyzeDocument(
        request: AnalyzeDocumentInput
    ) async throws -> AnalyzeDocumentOutputResponse {
        try await awsTextract.analyzeDocument(input: request)
    }

    func detectDocumentText(
        request: DetectDocumentTextInput
    ) async throws -> DetectDocumentTextOutputResponse {
        try await awsTextract.detectDocumentText(input: request)
    }

    func getTextract() -> TextractClient {
        awsTextract
    }
}
