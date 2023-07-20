//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
@testable import AWSPredictionsPlugin

class MockTranslateBehavior: TranslateClientProtocol {
    var translateTextResult: ((TranslateTextInput) async throws -> TranslateTextOutputResponse)? = nil

    func translateText(
        input: TranslateTextInput
    ) async throws -> TranslateTextOutputResponse {
        guard let translateTextResult else { throw MockBehaviorDefaultError() }
        return try await translateTextResult(input)
    }

    func getTranslate() -> AWSTranslate.TranslateClient {
        try! .init(region: "us-east-1")
    }
}

extension MockTranslateBehavior {
    func createParallelData(input: AWSTranslate.CreateParallelDataInput) async throws -> AWSTranslate.CreateParallelDataOutputResponse { fatalError() }
    func deleteParallelData(input: AWSTranslate.DeleteParallelDataInput) async throws -> AWSTranslate.DeleteParallelDataOutputResponse { fatalError() }
    func deleteTerminology(input: AWSTranslate.DeleteTerminologyInput) async throws -> AWSTranslate.DeleteTerminologyOutputResponse { fatalError() }
    func describeTextTranslationJob(input: AWSTranslate.DescribeTextTranslationJobInput) async throws -> AWSTranslate.DescribeTextTranslationJobOutputResponse { fatalError() }
    func getParallelData(input: AWSTranslate.GetParallelDataInput) async throws -> AWSTranslate.GetParallelDataOutputResponse { fatalError() }
    func getTerminology(input: AWSTranslate.GetTerminologyInput) async throws -> AWSTranslate.GetTerminologyOutputResponse { fatalError() }
    func importTerminology(input: AWSTranslate.ImportTerminologyInput) async throws -> AWSTranslate.ImportTerminologyOutputResponse { fatalError() }
    func listLanguages(input: AWSTranslate.ListLanguagesInput) async throws -> AWSTranslate.ListLanguagesOutputResponse { fatalError() }
    func listParallelData(input: AWSTranslate.ListParallelDataInput) async throws -> AWSTranslate.ListParallelDataOutputResponse { fatalError() }
    func listTagsForResource(input: AWSTranslate.ListTagsForResourceInput) async throws -> AWSTranslate.ListTagsForResourceOutputResponse { fatalError() }
    func listTerminologies(input: AWSTranslate.ListTerminologiesInput) async throws -> AWSTranslate.ListTerminologiesOutputResponse { fatalError() }
    func listTextTranslationJobs(input: AWSTranslate.ListTextTranslationJobsInput) async throws -> AWSTranslate.ListTextTranslationJobsOutputResponse { fatalError() }
    func startTextTranslationJob(input: AWSTranslate.StartTextTranslationJobInput) async throws -> AWSTranslate.StartTextTranslationJobOutputResponse { fatalError() }
    func stopTextTranslationJob(input: AWSTranslate.StopTextTranslationJobInput) async throws -> AWSTranslate.StopTextTranslationJobOutputResponse { fatalError() }
    func tagResource(input: AWSTranslate.TagResourceInput) async throws -> AWSTranslate.TagResourceOutputResponse { fatalError() }
    func untagResource(input: AWSTranslate.UntagResourceInput) async throws -> AWSTranslate.UntagResourceOutputResponse { fatalError() }
    func updateParallelData(input: AWSTranslate.UpdateParallelDataInput) async throws -> AWSTranslate.UpdateParallelDataOutputResponse { fatalError() }
}
