//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
@testable import AWSPredictionsPlugin

class MockComprehendBehavior: ComprehendClientProtocol {
    var sentimentResponse: ((DetectSentimentInput) async throws -> DetectSentimentOutput)? = nil
    var entitiesResponse: ((DetectEntitiesInput) async throws -> DetectEntitiesOutput)? = nil
    var languageResponse: ((DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutput)? = nil
    var syntaxResponse: ((DetectSyntaxInput) async throws -> DetectSyntaxOutput)? = nil
    var keyPhrasesResponse: ((DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutput)? = nil

    func detectSentiment(input: DetectSentimentInput) async throws -> DetectSentimentOutput {
        guard let sentimentResponse else { throw MockBehaviorDefaultError() }
        return try await sentimentResponse(input)
    }

    func detectEntities(input: DetectEntitiesInput) async throws -> DetectEntitiesOutput {
        guard let entitiesResponse else { throw MockBehaviorDefaultError() }
        return try await entitiesResponse(input)
    }

    func detectDominantLanguage(input: DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutput {
        guard let languageResponse else { throw MockBehaviorDefaultError() }
        return try await languageResponse(input)
    }

    func detectSyntax(input: DetectSyntaxInput) async throws -> DetectSyntaxOutput {
        guard let syntaxResponse else { throw MockBehaviorDefaultError() }
        return try await syntaxResponse(input)
    }

    func detectKeyPhrases(input: DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutput {
        guard let keyPhrasesResponse else { throw MockBehaviorDefaultError() }
        return try await keyPhrasesResponse(input)
    }

    func getComprehend() -> ComprehendClient {
        try! ComprehendClient(region: "us-east-1")
    }
}

// MARK: Unused ComprehendClientProtocol Methods
extension MockComprehendBehavior {
    func batchDetectDominantLanguage(input: AWSComprehend.BatchDetectDominantLanguageInput) async throws -> AWSComprehend.BatchDetectDominantLanguageOutput { fatalError() }
    func batchDetectEntities(input: AWSComprehend.BatchDetectEntitiesInput) async throws -> AWSComprehend.BatchDetectEntitiesOutput { fatalError() }
    func batchDetectKeyPhrases(input: AWSComprehend.BatchDetectKeyPhrasesInput) async throws -> AWSComprehend.BatchDetectKeyPhrasesOutput { fatalError() }
    func batchDetectSentiment(input: AWSComprehend.BatchDetectSentimentInput) async throws -> AWSComprehend.BatchDetectSentimentOutput { fatalError() }
    func batchDetectSyntax(input: AWSComprehend.BatchDetectSyntaxInput) async throws -> AWSComprehend.BatchDetectSyntaxOutput { fatalError() }
    func batchDetectTargetedSentiment(input: AWSComprehend.BatchDetectTargetedSentimentInput) async throws -> AWSComprehend.BatchDetectTargetedSentimentOutput { fatalError() }
    func classifyDocument(input: AWSComprehend.ClassifyDocumentInput) async throws -> AWSComprehend.ClassifyDocumentOutput { fatalError() }
    func containsPiiEntities(input: AWSComprehend.ContainsPiiEntitiesInput) async throws -> AWSComprehend.ContainsPiiEntitiesOutput { fatalError() }
    func createDocumentClassifier(input: AWSComprehend.CreateDocumentClassifierInput) async throws -> AWSComprehend.CreateDocumentClassifierOutput { fatalError() }
    func createEndpoint(input: AWSComprehend.CreateEndpointInput) async throws -> AWSComprehend.CreateEndpointOutput { fatalError() }
    func createEntityRecognizer(input: AWSComprehend.CreateEntityRecognizerInput) async throws -> AWSComprehend.CreateEntityRecognizerOutput { fatalError() }
    func deleteDocumentClassifier(input: AWSComprehend.DeleteDocumentClassifierInput) async throws -> AWSComprehend.DeleteDocumentClassifierOutput { fatalError() }
    func deleteEndpoint(input: AWSComprehend.DeleteEndpointInput) async throws -> AWSComprehend.DeleteEndpointOutput { fatalError() }
    func deleteEntityRecognizer(input: AWSComprehend.DeleteEntityRecognizerInput) async throws -> AWSComprehend.DeleteEntityRecognizerOutput { fatalError() }
    func deleteResourcePolicy(input: AWSComprehend.DeleteResourcePolicyInput) async throws -> AWSComprehend.DeleteResourcePolicyOutput { fatalError() }
    func describeDocumentClassificationJob(input: AWSComprehend.DescribeDocumentClassificationJobInput) async throws -> AWSComprehend.DescribeDocumentClassificationJobOutput { fatalError() }
    func describeDocumentClassifier(input: AWSComprehend.DescribeDocumentClassifierInput) async throws -> AWSComprehend.DescribeDocumentClassifierOutput { fatalError() }
    func describeDominantLanguageDetectionJob(input: AWSComprehend.DescribeDominantLanguageDetectionJobInput) async throws -> AWSComprehend.DescribeDominantLanguageDetectionJobOutput { fatalError() }
    func describeEndpoint(input: AWSComprehend.DescribeEndpointInput) async throws -> AWSComprehend.DescribeEndpointOutput { fatalError() }
    func describeEntitiesDetectionJob(input: AWSComprehend.DescribeEntitiesDetectionJobInput) async throws -> AWSComprehend.DescribeEntitiesDetectionJobOutput { fatalError() }
    func describeEntityRecognizer(input: AWSComprehend.DescribeEntityRecognizerInput) async throws -> AWSComprehend.DescribeEntityRecognizerOutput { fatalError() }
    func describeEventsDetectionJob(input: AWSComprehend.DescribeEventsDetectionJobInput) async throws -> AWSComprehend.DescribeEventsDetectionJobOutput { fatalError() }
    func describeKeyPhrasesDetectionJob(input: AWSComprehend.DescribeKeyPhrasesDetectionJobInput) async throws -> AWSComprehend.DescribeKeyPhrasesDetectionJobOutput { fatalError() }
    func describePiiEntitiesDetectionJob(input: AWSComprehend.DescribePiiEntitiesDetectionJobInput) async throws -> AWSComprehend.DescribePiiEntitiesDetectionJobOutput { fatalError() }
    func describeResourcePolicy(input: AWSComprehend.DescribeResourcePolicyInput) async throws -> AWSComprehend.DescribeResourcePolicyOutput { fatalError() }
    func describeSentimentDetectionJob(input: AWSComprehend.DescribeSentimentDetectionJobInput) async throws -> AWSComprehend.DescribeSentimentDetectionJobOutput { fatalError() }
    func describeTargetedSentimentDetectionJob(input: AWSComprehend.DescribeTargetedSentimentDetectionJobInput) async throws -> AWSComprehend.DescribeTargetedSentimentDetectionJobOutput { fatalError() }
    func describeTopicsDetectionJob(input: AWSComprehend.DescribeTopicsDetectionJobInput) async throws -> AWSComprehend.DescribeTopicsDetectionJobOutput { fatalError() }
    func detectPiiEntities(input: AWSComprehend.DetectPiiEntitiesInput) async throws -> AWSComprehend.DetectPiiEntitiesOutput { fatalError() }
    func detectTargetedSentiment(input: AWSComprehend.DetectTargetedSentimentInput) async throws -> AWSComprehend.DetectTargetedSentimentOutput { fatalError() }
    func importModel(input: AWSComprehend.ImportModelInput) async throws -> AWSComprehend.ImportModelOutput { fatalError() }
    func listDocumentClassificationJobs(input: AWSComprehend.ListDocumentClassificationJobsInput) async throws -> AWSComprehend.ListDocumentClassificationJobsOutput { fatalError() }
    func listDocumentClassifiers(input: AWSComprehend.ListDocumentClassifiersInput) async throws -> AWSComprehend.ListDocumentClassifiersOutput { fatalError() }
    func listDocumentClassifierSummaries(input: AWSComprehend.ListDocumentClassifierSummariesInput) async throws -> AWSComprehend.ListDocumentClassifierSummariesOutput { fatalError() }
    func listDominantLanguageDetectionJobs(input: AWSComprehend.ListDominantLanguageDetectionJobsInput) async throws -> AWSComprehend.ListDominantLanguageDetectionJobsOutput { fatalError() }
    func listEndpoints(input: AWSComprehend.ListEndpointsInput) async throws -> AWSComprehend.ListEndpointsOutput { fatalError() }
    func listEntitiesDetectionJobs(input: AWSComprehend.ListEntitiesDetectionJobsInput) async throws -> AWSComprehend.ListEntitiesDetectionJobsOutput { fatalError() }
    func listEntityRecognizers(input: AWSComprehend.ListEntityRecognizersInput) async throws -> AWSComprehend.ListEntityRecognizersOutput { fatalError() }
    func listEntityRecognizerSummaries(input: AWSComprehend.ListEntityRecognizerSummariesInput) async throws -> AWSComprehend.ListEntityRecognizerSummariesOutput { fatalError() }
    func listEventsDetectionJobs(input: AWSComprehend.ListEventsDetectionJobsInput) async throws -> AWSComprehend.ListEventsDetectionJobsOutput { fatalError() }
    func listKeyPhrasesDetectionJobs(input: AWSComprehend.ListKeyPhrasesDetectionJobsInput) async throws -> AWSComprehend.ListKeyPhrasesDetectionJobsOutput { fatalError() }
    func listPiiEntitiesDetectionJobs(input: AWSComprehend.ListPiiEntitiesDetectionJobsInput) async throws -> AWSComprehend.ListPiiEntitiesDetectionJobsOutput { fatalError() }
    func listSentimentDetectionJobs(input: AWSComprehend.ListSentimentDetectionJobsInput) async throws -> AWSComprehend.ListSentimentDetectionJobsOutput { fatalError() }
    func listTagsForResource(input: AWSComprehend.ListTagsForResourceInput) async throws -> AWSComprehend.ListTagsForResourceOutput { fatalError() }
    func listTargetedSentimentDetectionJobs(input: AWSComprehend.ListTargetedSentimentDetectionJobsInput) async throws -> AWSComprehend.ListTargetedSentimentDetectionJobsOutput { fatalError() }
    func listTopicsDetectionJobs(input: AWSComprehend.ListTopicsDetectionJobsInput) async throws -> AWSComprehend.ListTopicsDetectionJobsOutput { fatalError() }
    func putResourcePolicy(input: AWSComprehend.PutResourcePolicyInput) async throws -> AWSComprehend.PutResourcePolicyOutput { fatalError() }
    func startDocumentClassificationJob(input: AWSComprehend.StartDocumentClassificationJobInput) async throws -> AWSComprehend.StartDocumentClassificationJobOutput { fatalError() }
    func startDominantLanguageDetectionJob(input: AWSComprehend.StartDominantLanguageDetectionJobInput) async throws -> AWSComprehend.StartDominantLanguageDetectionJobOutput { fatalError() }
    func startEntitiesDetectionJob(input: AWSComprehend.StartEntitiesDetectionJobInput) async throws -> AWSComprehend.StartEntitiesDetectionJobOutput { fatalError() }
    func startEventsDetectionJob(input: AWSComprehend.StartEventsDetectionJobInput) async throws -> AWSComprehend.StartEventsDetectionJobOutput { fatalError() }
    func startKeyPhrasesDetectionJob(input: AWSComprehend.StartKeyPhrasesDetectionJobInput) async throws -> AWSComprehend.StartKeyPhrasesDetectionJobOutput { fatalError() }
    func startPiiEntitiesDetectionJob(input: AWSComprehend.StartPiiEntitiesDetectionJobInput) async throws -> AWSComprehend.StartPiiEntitiesDetectionJobOutput { fatalError() }
    func startSentimentDetectionJob(input: AWSComprehend.StartSentimentDetectionJobInput) async throws -> AWSComprehend.StartSentimentDetectionJobOutput { fatalError() }
    func startTargetedSentimentDetectionJob(input: AWSComprehend.StartTargetedSentimentDetectionJobInput) async throws -> AWSComprehend.StartTargetedSentimentDetectionJobOutput { fatalError() }
    func startTopicsDetectionJob(input: AWSComprehend.StartTopicsDetectionJobInput) async throws -> AWSComprehend.StartTopicsDetectionJobOutput { fatalError() }
    func stopDominantLanguageDetectionJob(input: AWSComprehend.StopDominantLanguageDetectionJobInput) async throws -> AWSComprehend.StopDominantLanguageDetectionJobOutput { fatalError() }
    func stopEntitiesDetectionJob(input: AWSComprehend.StopEntitiesDetectionJobInput) async throws -> AWSComprehend.StopEntitiesDetectionJobOutput { fatalError() }
    func stopEventsDetectionJob(input: AWSComprehend.StopEventsDetectionJobInput) async throws -> AWSComprehend.StopEventsDetectionJobOutput { fatalError() }
    func stopKeyPhrasesDetectionJob(input: AWSComprehend.StopKeyPhrasesDetectionJobInput) async throws -> AWSComprehend.StopKeyPhrasesDetectionJobOutput { fatalError() }
    func stopPiiEntitiesDetectionJob(input: AWSComprehend.StopPiiEntitiesDetectionJobInput) async throws -> AWSComprehend.StopPiiEntitiesDetectionJobOutput { fatalError() }
    func stopSentimentDetectionJob(input: AWSComprehend.StopSentimentDetectionJobInput) async throws -> AWSComprehend.StopSentimentDetectionJobOutput { fatalError() }
    func stopTargetedSentimentDetectionJob(input: AWSComprehend.StopTargetedSentimentDetectionJobInput) async throws -> AWSComprehend.StopTargetedSentimentDetectionJobOutput { fatalError() }
    func stopTrainingDocumentClassifier(input: AWSComprehend.StopTrainingDocumentClassifierInput) async throws -> AWSComprehend.StopTrainingDocumentClassifierOutput { fatalError() }
    func stopTrainingEntityRecognizer(input: AWSComprehend.StopTrainingEntityRecognizerInput) async throws -> AWSComprehend.StopTrainingEntityRecognizerOutput { fatalError() }
    func tagResource(input: AWSComprehend.TagResourceInput) async throws -> AWSComprehend.TagResourceOutput { fatalError() }
    func untagResource(input: AWSComprehend.UntagResourceInput) async throws -> AWSComprehend.UntagResourceOutput { fatalError() }
    func updateEndpoint(input: AWSComprehend.UpdateEndpointInput) async throws -> AWSComprehend.UpdateEndpointOutput { fatalError() }
    func createDataset(input: AWSComprehend.CreateDatasetInput) async throws -> AWSComprehend.CreateDatasetOutput { fatalError() }
    func createFlywheel(input: AWSComprehend.CreateFlywheelInput) async throws -> AWSComprehend.CreateFlywheelOutput { fatalError() }
    func deleteFlywheel(input: AWSComprehend.DeleteFlywheelInput) async throws -> AWSComprehend.DeleteFlywheelOutput { fatalError() }
    func describeDataset(input: AWSComprehend.DescribeDatasetInput) async throws -> AWSComprehend.DescribeDatasetOutput { fatalError() }
    func describeFlywheel(input: AWSComprehend.DescribeFlywheelInput) async throws -> AWSComprehend.DescribeFlywheelOutput { fatalError() }
    func describeFlywheelIteration(input: AWSComprehend.DescribeFlywheelIterationInput) async throws -> AWSComprehend.DescribeFlywheelIterationOutput { fatalError() }
    func listDatasets(input: AWSComprehend.ListDatasetsInput) async throws -> AWSComprehend.ListDatasetsOutput { fatalError() }
    func listFlywheelIterationHistory(input: AWSComprehend.ListFlywheelIterationHistoryInput) async throws -> AWSComprehend.ListFlywheelIterationHistoryOutput { fatalError() }
    func listFlywheels(input: AWSComprehend.ListFlywheelsInput) async throws -> AWSComprehend.ListFlywheelsOutput { fatalError() }
    func startFlywheelIteration(input: AWSComprehend.StartFlywheelIterationInput) async throws -> AWSComprehend.StartFlywheelIterationOutput { fatalError() }
    func updateFlywheel(input: AWSComprehend.UpdateFlywheelInput) async throws -> AWSComprehend.UpdateFlywheelOutput { fatalError() }
    func detectToxicContent(input: AWSComprehend.DetectToxicContentInput) async throws -> AWSComprehend.DetectToxicContentOutput { fatalError() }
}
