//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTextract
@testable import AWSPredictionsPlugin

struct MockBehaviorDefaultError: Error {}

class MockTextractBehavior: TextractClientProtocol {
    var analyzeDocumentResult: ((AnalyzeDocumentInput) async throws -> AnalyzeDocumentOutputResponse)? = nil
    var detectDocumentTextResult: ((DetectDocumentTextInput) async throws -> DetectDocumentTextOutputResponse)? = nil

    func analyzeDocument(
        input: AnalyzeDocumentInput
    ) async throws -> AnalyzeDocumentOutputResponse {
        guard let analyzeDocumentResult else { throw MockBehaviorDefaultError() }
        return try await analyzeDocumentResult(input)
    }

    func detectDocumentText(
        input: DetectDocumentTextInput
    ) async throws -> DetectDocumentTextOutputResponse {
        guard let detectDocumentTextResult else { throw MockBehaviorDefaultError() }
        return try await detectDocumentTextResult(input)
    }

    func getTextract() -> AWSTextract.TextractClient {
        try! .init(region: "us-east-1")
    }
}

extension MockTextractBehavior {
    func analyzeExpense(input: AWSTextract.AnalyzeExpenseInput) async throws -> AWSTextract.AnalyzeExpenseOutputResponse { fatalError() }
    func analyzeID(input: AWSTextract.AnalyzeIDInput) async throws -> AWSTextract.AnalyzeIDOutputResponse { fatalError() }
    func getDocumentAnalysis(input: AWSTextract.GetDocumentAnalysisInput) async throws -> AWSTextract.GetDocumentAnalysisOutputResponse { fatalError() }
    func getDocumentTextDetection(input: AWSTextract.GetDocumentTextDetectionInput) async throws -> AWSTextract.GetDocumentTextDetectionOutputResponse { fatalError() }
    func getExpenseAnalysis(input: AWSTextract.GetExpenseAnalysisInput) async throws -> AWSTextract.GetExpenseAnalysisOutputResponse { fatalError() }
    func getLendingAnalysis(input: AWSTextract.GetLendingAnalysisInput) async throws -> AWSTextract.GetLendingAnalysisOutputResponse { fatalError() }
    func getLendingAnalysisSummary(input: AWSTextract.GetLendingAnalysisSummaryInput) async throws -> AWSTextract.GetLendingAnalysisSummaryOutputResponse { fatalError() }
    func startDocumentAnalysis(input: AWSTextract.StartDocumentAnalysisInput) async throws -> AWSTextract.StartDocumentAnalysisOutputResponse { fatalError() }
    func startDocumentTextDetection(input: AWSTextract.StartDocumentTextDetectionInput) async throws -> AWSTextract.StartDocumentTextDetectionOutputResponse { fatalError() }
    func startExpenseAnalysis(input: AWSTextract.StartExpenseAnalysisInput) async throws -> AWSTextract.StartExpenseAnalysisOutputResponse { fatalError() }
    func startLendingAnalysis(input: AWSTextract.StartLendingAnalysisInput) async throws -> AWSTextract.StartLendingAnalysisOutputResponse { fatalError() }
}
