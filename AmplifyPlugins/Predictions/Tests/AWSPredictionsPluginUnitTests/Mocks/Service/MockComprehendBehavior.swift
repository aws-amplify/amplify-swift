//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
@testable import AWSPredictionsPlugin

class MockComprehendBehavior: ComprehendClientProtocol {
    var sentimentResponse: ((DetectSentimentInput) async throws -> DetectSentimentOutputResponse)? = nil
    var entitiesResponse: ((DetectEntitiesInput) async throws -> DetectEntitiesOutputResponse)? = nil
    var languageResponse: ((DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutputResponse)? = nil
    var syntaxResponse: ((DetectSyntaxInput) async throws -> DetectSyntaxOutputResponse)? = nil
    var keyPhrasesResponse: ((DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutputResponse)? = nil

    func detectSentiment(input: DetectSentimentInput) async throws -> DetectSentimentOutputResponse {
        guard let sentimentResponse else { throw MockBehaviorDefaultError() }
        return try await sentimentResponse(input)
    }

    func detectEntities(input: DetectEntitiesInput) async throws -> DetectEntitiesOutputResponse {
        guard let entitiesResponse else { throw MockBehaviorDefaultError() }
        return try await entitiesResponse(input)
    }

    func detectDominantLanguage(input: DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutputResponse {
        guard let languageResponse else { throw MockBehaviorDefaultError() }
        return try await languageResponse(input)
    }

    func detectSyntax(input: DetectSyntaxInput) async throws -> DetectSyntaxOutputResponse {
        guard let syntaxResponse else { throw MockBehaviorDefaultError() }
        return try await syntaxResponse(input)
    }

    func detectKeyPhrases(input: DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutputResponse {
        guard let keyPhrasesResponse else { throw MockBehaviorDefaultError() }
        return try await keyPhrasesResponse(input)
    }

    func getComprehend() -> ComprehendClient {
        try! ComprehendClient(region: "us-east-1")
    }
}

// MARK: Unused ComprehendClientProtocol Methods
extension MockComprehendBehavior {
    func batchDetectDominantLanguage(input: AWSComprehend.BatchDetectDominantLanguageInput) async throws -> AWSComprehend.BatchDetectDominantLanguageOutputResponse { fatalError() }
    func batchDetectEntities(input: AWSComprehend.BatchDetectEntitiesInput) async throws -> AWSComprehend.BatchDetectEntitiesOutputResponse { fatalError() }
    func batchDetectKeyPhrases(input: AWSComprehend.BatchDetectKeyPhrasesInput) async throws -> AWSComprehend.BatchDetectKeyPhrasesOutputResponse { fatalError() }
    func batchDetectSentiment(input: AWSComprehend.BatchDetectSentimentInput) async throws -> AWSComprehend.BatchDetectSentimentOutputResponse { fatalError() }
    func batchDetectSyntax(input: AWSComprehend.BatchDetectSyntaxInput) async throws -> AWSComprehend.BatchDetectSyntaxOutputResponse { fatalError() }
    func batchDetectTargetedSentiment(input: AWSComprehend.BatchDetectTargetedSentimentInput) async throws -> AWSComprehend.BatchDetectTargetedSentimentOutputResponse { fatalError() }
    func classifyDocument(input: AWSComprehend.ClassifyDocumentInput) async throws -> AWSComprehend.ClassifyDocumentOutputResponse { fatalError() }
    func containsPiiEntities(input: AWSComprehend.ContainsPiiEntitiesInput) async throws -> AWSComprehend.ContainsPiiEntitiesOutputResponse { fatalError() }
    func createDocumentClassifier(input: AWSComprehend.CreateDocumentClassifierInput) async throws -> AWSComprehend.CreateDocumentClassifierOutputResponse { fatalError() }
    func createEndpoint(input: AWSComprehend.CreateEndpointInput) async throws -> AWSComprehend.CreateEndpointOutputResponse { fatalError() }
    func createEntityRecognizer(input: AWSComprehend.CreateEntityRecognizerInput) async throws -> AWSComprehend.CreateEntityRecognizerOutputResponse { fatalError() }
    func deleteDocumentClassifier(input: AWSComprehend.DeleteDocumentClassifierInput) async throws -> AWSComprehend.DeleteDocumentClassifierOutputResponse { fatalError() }
    func deleteEndpoint(input: AWSComprehend.DeleteEndpointInput) async throws -> AWSComprehend.DeleteEndpointOutputResponse { fatalError() }
    func deleteEntityRecognizer(input: AWSComprehend.DeleteEntityRecognizerInput) async throws -> AWSComprehend.DeleteEntityRecognizerOutputResponse { fatalError() }
    func deleteResourcePolicy(input: AWSComprehend.DeleteResourcePolicyInput) async throws -> AWSComprehend.DeleteResourcePolicyOutputResponse { fatalError() }
    func describeDocumentClassificationJob(input: AWSComprehend.DescribeDocumentClassificationJobInput) async throws -> AWSComprehend.DescribeDocumentClassificationJobOutputResponse { fatalError() }
    func describeDocumentClassifier(input: AWSComprehend.DescribeDocumentClassifierInput) async throws -> AWSComprehend.DescribeDocumentClassifierOutputResponse { fatalError() }
    func describeDominantLanguageDetectionJob(input: AWSComprehend.DescribeDominantLanguageDetectionJobInput) async throws -> AWSComprehend.DescribeDominantLanguageDetectionJobOutputResponse { fatalError() }
    func describeEndpoint(input: AWSComprehend.DescribeEndpointInput) async throws -> AWSComprehend.DescribeEndpointOutputResponse { fatalError() }
    func describeEntitiesDetectionJob(input: AWSComprehend.DescribeEntitiesDetectionJobInput) async throws -> AWSComprehend.DescribeEntitiesDetectionJobOutputResponse { fatalError() }
    func describeEntityRecognizer(input: AWSComprehend.DescribeEntityRecognizerInput) async throws -> AWSComprehend.DescribeEntityRecognizerOutputResponse { fatalError() }
    func describeEventsDetectionJob(input: AWSComprehend.DescribeEventsDetectionJobInput) async throws -> AWSComprehend.DescribeEventsDetectionJobOutputResponse { fatalError() }
    func describeKeyPhrasesDetectionJob(input: AWSComprehend.DescribeKeyPhrasesDetectionJobInput) async throws -> AWSComprehend.DescribeKeyPhrasesDetectionJobOutputResponse { fatalError() }
    func describePiiEntitiesDetectionJob(input: AWSComprehend.DescribePiiEntitiesDetectionJobInput) async throws -> AWSComprehend.DescribePiiEntitiesDetectionJobOutputResponse { fatalError() }
    func describeResourcePolicy(input: AWSComprehend.DescribeResourcePolicyInput) async throws -> AWSComprehend.DescribeResourcePolicyOutputResponse { fatalError() }
    func describeSentimentDetectionJob(input: AWSComprehend.DescribeSentimentDetectionJobInput) async throws -> AWSComprehend.DescribeSentimentDetectionJobOutputResponse { fatalError() }
    func describeTargetedSentimentDetectionJob(input: AWSComprehend.DescribeTargetedSentimentDetectionJobInput) async throws -> AWSComprehend.DescribeTargetedSentimentDetectionJobOutputResponse { fatalError() }
    func describeTopicsDetectionJob(input: AWSComprehend.DescribeTopicsDetectionJobInput) async throws -> AWSComprehend.DescribeTopicsDetectionJobOutputResponse { fatalError() }
    func detectPiiEntities(input: AWSComprehend.DetectPiiEntitiesInput) async throws -> AWSComprehend.DetectPiiEntitiesOutputResponse { fatalError() }
    func detectTargetedSentiment(input: AWSComprehend.DetectTargetedSentimentInput) async throws -> AWSComprehend.DetectTargetedSentimentOutputResponse { fatalError() }
    func importModel(input: AWSComprehend.ImportModelInput) async throws -> AWSComprehend.ImportModelOutputResponse { fatalError() }
    func listDocumentClassificationJobs(input: AWSComprehend.ListDocumentClassificationJobsInput) async throws -> AWSComprehend.ListDocumentClassificationJobsOutputResponse { fatalError() }
    func listDocumentClassifiers(input: AWSComprehend.ListDocumentClassifiersInput) async throws -> AWSComprehend.ListDocumentClassifiersOutputResponse { fatalError() }
    func listDocumentClassifierSummaries(input: AWSComprehend.ListDocumentClassifierSummariesInput) async throws -> AWSComprehend.ListDocumentClassifierSummariesOutputResponse { fatalError() }
    func listDominantLanguageDetectionJobs(input: AWSComprehend.ListDominantLanguageDetectionJobsInput) async throws -> AWSComprehend.ListDominantLanguageDetectionJobsOutputResponse { fatalError() }
    func listEndpoints(input: AWSComprehend.ListEndpointsInput) async throws -> AWSComprehend.ListEndpointsOutputResponse { fatalError() }
    func listEntitiesDetectionJobs(input: AWSComprehend.ListEntitiesDetectionJobsInput) async throws -> AWSComprehend.ListEntitiesDetectionJobsOutputResponse { fatalError() }
    func listEntityRecognizers(input: AWSComprehend.ListEntityRecognizersInput) async throws -> AWSComprehend.ListEntityRecognizersOutputResponse { fatalError() }
    func listEntityRecognizerSummaries(input: AWSComprehend.ListEntityRecognizerSummariesInput) async throws -> AWSComprehend.ListEntityRecognizerSummariesOutputResponse { fatalError() }
    func listEventsDetectionJobs(input: AWSComprehend.ListEventsDetectionJobsInput) async throws -> AWSComprehend.ListEventsDetectionJobsOutputResponse { fatalError() }
    func listKeyPhrasesDetectionJobs(input: AWSComprehend.ListKeyPhrasesDetectionJobsInput) async throws -> AWSComprehend.ListKeyPhrasesDetectionJobsOutputResponse { fatalError() }
    func listPiiEntitiesDetectionJobs(input: AWSComprehend.ListPiiEntitiesDetectionJobsInput) async throws -> AWSComprehend.ListPiiEntitiesDetectionJobsOutputResponse { fatalError() }
    func listSentimentDetectionJobs(input: AWSComprehend.ListSentimentDetectionJobsInput) async throws -> AWSComprehend.ListSentimentDetectionJobsOutputResponse { fatalError() }
    func listTagsForResource(input: AWSComprehend.ListTagsForResourceInput) async throws -> AWSComprehend.ListTagsForResourceOutputResponse { fatalError() }
    func listTargetedSentimentDetectionJobs(input: AWSComprehend.ListTargetedSentimentDetectionJobsInput) async throws -> AWSComprehend.ListTargetedSentimentDetectionJobsOutputResponse { fatalError() }
    func listTopicsDetectionJobs(input: AWSComprehend.ListTopicsDetectionJobsInput) async throws -> AWSComprehend.ListTopicsDetectionJobsOutputResponse { fatalError() }
    func putResourcePolicy(input: AWSComprehend.PutResourcePolicyInput) async throws -> AWSComprehend.PutResourcePolicyOutputResponse { fatalError() }
    func startDocumentClassificationJob(input: AWSComprehend.StartDocumentClassificationJobInput) async throws -> AWSComprehend.StartDocumentClassificationJobOutputResponse { fatalError() }
    func startDominantLanguageDetectionJob(input: AWSComprehend.StartDominantLanguageDetectionJobInput) async throws -> AWSComprehend.StartDominantLanguageDetectionJobOutputResponse { fatalError() }
    func startEntitiesDetectionJob(input: AWSComprehend.StartEntitiesDetectionJobInput) async throws -> AWSComprehend.StartEntitiesDetectionJobOutputResponse { fatalError() }
    func startEventsDetectionJob(input: AWSComprehend.StartEventsDetectionJobInput) async throws -> AWSComprehend.StartEventsDetectionJobOutputResponse { fatalError() }
    func startKeyPhrasesDetectionJob(input: AWSComprehend.StartKeyPhrasesDetectionJobInput) async throws -> AWSComprehend.StartKeyPhrasesDetectionJobOutputResponse { fatalError() }
    func startPiiEntitiesDetectionJob(input: AWSComprehend.StartPiiEntitiesDetectionJobInput) async throws -> AWSComprehend.StartPiiEntitiesDetectionJobOutputResponse { fatalError() }
    func startSentimentDetectionJob(input: AWSComprehend.StartSentimentDetectionJobInput) async throws -> AWSComprehend.StartSentimentDetectionJobOutputResponse { fatalError() }
    func startTargetedSentimentDetectionJob(input: AWSComprehend.StartTargetedSentimentDetectionJobInput) async throws -> AWSComprehend.StartTargetedSentimentDetectionJobOutputResponse { fatalError() }
    func startTopicsDetectionJob(input: AWSComprehend.StartTopicsDetectionJobInput) async throws -> AWSComprehend.StartTopicsDetectionJobOutputResponse { fatalError() }
    func stopDominantLanguageDetectionJob(input: AWSComprehend.StopDominantLanguageDetectionJobInput) async throws -> AWSComprehend.StopDominantLanguageDetectionJobOutputResponse { fatalError() }
    func stopEntitiesDetectionJob(input: AWSComprehend.StopEntitiesDetectionJobInput) async throws -> AWSComprehend.StopEntitiesDetectionJobOutputResponse { fatalError() }
    func stopEventsDetectionJob(input: AWSComprehend.StopEventsDetectionJobInput) async throws -> AWSComprehend.StopEventsDetectionJobOutputResponse { fatalError() }
    func stopKeyPhrasesDetectionJob(input: AWSComprehend.StopKeyPhrasesDetectionJobInput) async throws -> AWSComprehend.StopKeyPhrasesDetectionJobOutputResponse { fatalError() }
    func stopPiiEntitiesDetectionJob(input: AWSComprehend.StopPiiEntitiesDetectionJobInput) async throws -> AWSComprehend.StopPiiEntitiesDetectionJobOutputResponse { fatalError() }
    func stopSentimentDetectionJob(input: AWSComprehend.StopSentimentDetectionJobInput) async throws -> AWSComprehend.StopSentimentDetectionJobOutputResponse { fatalError() }
    func stopTargetedSentimentDetectionJob(input: AWSComprehend.StopTargetedSentimentDetectionJobInput) async throws -> AWSComprehend.StopTargetedSentimentDetectionJobOutputResponse { fatalError() }
    func stopTrainingDocumentClassifier(input: AWSComprehend.StopTrainingDocumentClassifierInput) async throws -> AWSComprehend.StopTrainingDocumentClassifierOutputResponse { fatalError() }
    func stopTrainingEntityRecognizer(input: AWSComprehend.StopTrainingEntityRecognizerInput) async throws -> AWSComprehend.StopTrainingEntityRecognizerOutputResponse { fatalError() }
    func tagResource(input: AWSComprehend.TagResourceInput) async throws -> AWSComprehend.TagResourceOutputResponse { fatalError() }
    func untagResource(input: AWSComprehend.UntagResourceInput) async throws -> AWSComprehend.UntagResourceOutputResponse { fatalError() }
    func updateEndpoint(input: AWSComprehend.UpdateEndpointInput) async throws -> AWSComprehend.UpdateEndpointOutputResponse { fatalError() }
    func createDataset(input: AWSComprehend.CreateDatasetInput) async throws -> AWSComprehend.CreateDatasetOutputResponse { fatalError() }
    func createFlywheel(input: AWSComprehend.CreateFlywheelInput) async throws -> AWSComprehend.CreateFlywheelOutputResponse { fatalError() }
    func deleteFlywheel(input: AWSComprehend.DeleteFlywheelInput) async throws -> AWSComprehend.DeleteFlywheelOutputResponse { fatalError() }
    func describeDataset(input: AWSComprehend.DescribeDatasetInput) async throws -> AWSComprehend.DescribeDatasetOutputResponse { fatalError() }
    func describeFlywheel(input: AWSComprehend.DescribeFlywheelInput) async throws -> AWSComprehend.DescribeFlywheelOutputResponse { fatalError() }
    func describeFlywheelIteration(input: AWSComprehend.DescribeFlywheelIterationInput) async throws -> AWSComprehend.DescribeFlywheelIterationOutputResponse { fatalError() }
    func listDatasets(input: AWSComprehend.ListDatasetsInput) async throws -> AWSComprehend.ListDatasetsOutputResponse { fatalError() }
    func listFlywheelIterationHistory(input: AWSComprehend.ListFlywheelIterationHistoryInput) async throws -> AWSComprehend.ListFlywheelIterationHistoryOutputResponse { fatalError() }
    func listFlywheels(input: AWSComprehend.ListFlywheelsInput) async throws -> AWSComprehend.ListFlywheelsOutputResponse { fatalError() }
    func startFlywheelIteration(input: AWSComprehend.StartFlywheelIterationInput) async throws -> AWSComprehend.StartFlywheelIterationOutputResponse { fatalError() }
    func updateFlywheel(input: AWSComprehend.UpdateFlywheelInput) async throws -> AWSComprehend.UpdateFlywheelOutputResponse { fatalError() }
}
