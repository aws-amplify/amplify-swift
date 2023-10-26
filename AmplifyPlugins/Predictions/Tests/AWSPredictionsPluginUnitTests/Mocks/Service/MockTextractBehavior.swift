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
    var analyzeDocumentResult: ((AnalyzeDocumentInput) async throws -> AnalyzeDocumentOutput)? = nil
    var detectDocumentTextResult: ((DetectDocumentTextInput) async throws -> DetectDocumentTextOutput)? = nil

    func analyzeDocument(
        input: AnalyzeDocumentInput
    ) async throws -> AnalyzeDocumentOutput {
        guard let analyzeDocumentResult else { throw MockBehaviorDefaultError() }
        return try await analyzeDocumentResult(input)
    }

    func detectDocumentText(
        input: DetectDocumentTextInput
    ) async throws -> DetectDocumentTextOutput {
        guard let detectDocumentTextResult else { throw MockBehaviorDefaultError() }
        return try await detectDocumentTextResult(input)
    }

    func getTextract() -> AWSTextract.TextractClient {
        try! .init(region: "us-east-1")
    }
}

extension MockTextractBehavior {
    func analyzeExpense(input: AWSTextract.AnalyzeExpenseInput) async throws -> AWSTextract.AnalyzeExpenseOutput { fatalError() }
    func analyzeID(input: AWSTextract.AnalyzeIDInput) async throws -> AWSTextract.AnalyzeIDOutput { fatalError() }
    func getDocumentAnalysis(input: AWSTextract.GetDocumentAnalysisInput) async throws -> AWSTextract.GetDocumentAnalysisOutput { fatalError() }
    func getDocumentTextDetection(input: AWSTextract.GetDocumentTextDetectionInput) async throws -> AWSTextract.GetDocumentTextDetectionOutput { fatalError() }
    func getExpenseAnalysis(input: AWSTextract.GetExpenseAnalysisInput) async throws -> AWSTextract.GetExpenseAnalysisOutput { fatalError() }
    func getLendingAnalysis(input: AWSTextract.GetLendingAnalysisInput) async throws -> AWSTextract.GetLendingAnalysisOutput { fatalError() }
    func getLendingAnalysisSummary(input: AWSTextract.GetLendingAnalysisSummaryInput) async throws -> AWSTextract.GetLendingAnalysisSummaryOutput { fatalError() }
    func startDocumentAnalysis(input: AWSTextract.StartDocumentAnalysisInput) async throws -> AWSTextract.StartDocumentAnalysisOutput { fatalError() }
    func startDocumentTextDetection(input: AWSTextract.StartDocumentTextDetectionInput) async throws -> AWSTextract.StartDocumentTextDetectionOutput { fatalError() }
    func startExpenseAnalysis(input: AWSTextract.StartExpenseAnalysisInput) async throws -> AWSTextract.StartExpenseAnalysisOutput { fatalError() }
    func startLendingAnalysis(input: AWSTextract.StartLendingAnalysisInput) async throws -> AWSTextract.StartLendingAnalysisOutput { fatalError() }
    func createAdapter(input: AWSTextract.CreateAdapterInput) async throws -> AWSTextract.CreateAdapterOutput {
        fatalError()
    }

    func createAdapterVersion(input: AWSTextract.CreateAdapterVersionInput) async throws -> AWSTextract.CreateAdapterVersionOutput {
        fatalError()
    }

    func deleteAdapter(input: AWSTextract.DeleteAdapterInput) async throws -> AWSTextract.DeleteAdapterOutput {
        fatalError()
    }

    func deleteAdapterVersion(input: AWSTextract.DeleteAdapterVersionInput) async throws -> AWSTextract.DeleteAdapterVersionOutput {
        fatalError()
    }

    func getAdapter(input: AWSTextract.GetAdapterInput) async throws -> AWSTextract.GetAdapterOutput {
        fatalError()
    }

    func getAdapterVersion(input: AWSTextract.GetAdapterVersionInput) async throws -> AWSTextract.GetAdapterVersionOutput {
        fatalError()
    }

    func listAdapters(input: AWSTextract.ListAdaptersInput) async throws -> AWSTextract.ListAdaptersOutput {
        fatalError()
    }

    func listAdapterVersions(input: AWSTextract.ListAdapterVersionsInput) async throws -> AWSTextract.ListAdapterVersionsOutput {
        fatalError()
    }

    func listTagsForResource(input: AWSTextract.ListTagsForResourceInput) async throws -> AWSTextract.ListTagsForResourceOutput {
        fatalError()
    }

    func tagResource(input: AWSTextract.TagResourceInput) async throws -> AWSTextract.TagResourceOutput {
        fatalError()
    }

    func untagResource(input: AWSTextract.UntagResourceInput) async throws -> AWSTextract.UntagResourceOutput {
        fatalError()
    }

    func updateAdapter(input: AWSTextract.UpdateAdapterInput) async throws -> AWSTextract.UpdateAdapterOutput {
        fatalError()
    }
}
