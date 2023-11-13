//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSPredictionsPlugin

struct MockBehaviorDefaultError: Error {}

//class MockTextractBehavior: TextractClient {
//    var analyzeDocumentResult: ((AnalyzeDocumentInput) async throws -> AnalyzeDocumentOutputResponse)? = nil
//    var detectDocumentTextResult: ((DetectDocumentTextInput) async throws -> DetectDocumentTextOutputResponse)? = nil
//
//    func analyzeDocument(
//        input: AnalyzeDocumentInput
//    ) async throws -> AnalyzeDocumentOutputResponse {
//        guard let analyzeDocumentResult else { throw MockBehaviorDefaultError() }
//        return try await analyzeDocumentResult(input)
//    }
//
//    func detectDocumentText(
//        input: DetectDocumentTextInput
//    ) async throws -> DetectDocumentTextOutputResponse {
//        guard let detectDocumentTextResult else { throw MockBehaviorDefaultError() }
//        return try await detectDocumentTextResult(input)
//    }
//
//    func getTextract() -> AWSTextract.TextractClient {
//        try! .init(region: "us-east-1")
//    }
//}
