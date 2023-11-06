//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
@testable import AWSPredictionsPlugin

class MockTranslateBehavior: TranslateClientProtocol {
    var translateTextResult: ((TranslateTextInput) async throws -> TranslateTextOutput)? = nil

    func translateText(
        input: TranslateTextInput
    ) async throws -> TranslateTextOutput {
        guard let translateTextResult else { throw MockBehaviorDefaultError() }
        return try await translateTextResult(input)
    }

    func getTranslate() -> AWSTranslate.TranslateClient {
        try! .init(region: "us-east-1")
    }
}

extension MockTranslateBehavior {
    func createParallelData(input: AWSTranslate.CreateParallelDataInput) async throws -> AWSTranslate.CreateParallelDataOutput { fatalError() }
    func deleteParallelData(input: AWSTranslate.DeleteParallelDataInput) async throws -> AWSTranslate.DeleteParallelDataOutput { fatalError() }
    func deleteTerminology(input: AWSTranslate.DeleteTerminologyInput) async throws -> AWSTranslate.DeleteTerminologyOutput { fatalError() }
    func describeTextTranslationJob(input: AWSTranslate.DescribeTextTranslationJobInput) async throws -> AWSTranslate.DescribeTextTranslationJobOutput { fatalError() }
    func getParallelData(input: AWSTranslate.GetParallelDataInput) async throws -> AWSTranslate.GetParallelDataOutput { fatalError() }
    func getTerminology(input: AWSTranslate.GetTerminologyInput) async throws -> AWSTranslate.GetTerminologyOutput { fatalError() }
    func importTerminology(input: AWSTranslate.ImportTerminologyInput) async throws -> AWSTranslate.ImportTerminologyOutput { fatalError() }
    func listLanguages(input: AWSTranslate.ListLanguagesInput) async throws -> AWSTranslate.ListLanguagesOutput { fatalError() }
    func listParallelData(input: AWSTranslate.ListParallelDataInput) async throws -> AWSTranslate.ListParallelDataOutput { fatalError() }
    func listTagsForResource(input: AWSTranslate.ListTagsForResourceInput) async throws -> AWSTranslate.ListTagsForResourceOutput { fatalError() }
    func listTerminologies(input: AWSTranslate.ListTerminologiesInput) async throws -> AWSTranslate.ListTerminologiesOutput { fatalError() }
    func listTextTranslationJobs(input: AWSTranslate.ListTextTranslationJobsInput) async throws -> AWSTranslate.ListTextTranslationJobsOutput { fatalError() }
    func startTextTranslationJob(input: AWSTranslate.StartTextTranslationJobInput) async throws -> AWSTranslate.StartTextTranslationJobOutput { fatalError() }
    func stopTextTranslationJob(input: AWSTranslate.StopTextTranslationJobInput) async throws -> AWSTranslate.StopTextTranslationJobOutput { fatalError() }
    func tagResource(input: AWSTranslate.TagResourceInput) async throws -> AWSTranslate.TagResourceOutput { fatalError() }
    func untagResource(input: AWSTranslate.UntagResourceInput) async throws -> AWSTranslate.UntagResourceOutput { fatalError() }
    func updateParallelData(input: AWSTranslate.UpdateParallelDataInput) async throws -> AWSTranslate.UpdateParallelDataOutput { fatalError() }
    func translateDocument(input: AWSTranslate.TranslateDocumentInput) async throws -> AWSTranslate.TranslateDocumentOutput { fatalError() }
}
