//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
//import AWSCore
import AWSTextract
@testable import AWSPredictionsPlugin

struct MockBehaviorDefaultError: Error {}

class MockTextractBehavior: AWSTextractBehavior {
    var analyzeDocumentResult: ((AnalyzeDocumentInput) async throws -> AnalyzeDocumentOutputResponse)? = nil
    var detectDocumentTextResult: ((DetectDocumentTextInput) async throws -> DetectDocumentTextOutputResponse)? = nil

    func analyzeDocument(
        request: AnalyzeDocumentInput
    ) async throws -> AnalyzeDocumentOutputResponse {
        guard let analyzeDocumentResult else { throw MockBehaviorDefaultError() }
        return try await analyzeDocumentResult(request)
    }

    func detectDocumentText(
        request: DetectDocumentTextInput
    ) async throws -> DetectDocumentTextOutputResponse {
        guard let detectDocumentTextResult else { throw MockBehaviorDefaultError() }
        return try await detectDocumentTextResult(request)
    }

    func getTextract() async throws -> TextractClient {
        try await TextractClient()
    }
}
