//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
@testable import AWSPredictionsPlugin

class MockRekognitionBehavior: RekognitionClientProtocol {
    var detectLabelsResponse: ((DetectLabelsInput) async throws -> DetectLabelsOutput)? = nil
    var moderationLabelsResponse: ((DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutput)? = nil
    var celebritiesResponse: ((RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutput)? = nil
    var detectTextResponse: ((DetectTextInput) async throws -> DetectTextOutput)? = nil
    var facesResponse: ((DetectFacesInput) async throws -> DetectFacesOutput)? = nil
    var facesFromCollectionResponse: ((SearchFacesByImageInput) async throws -> SearchFacesByImageOutput)? = nil

    func detectLabels(input: DetectLabelsInput) async throws -> DetectLabelsOutput {
        guard let detectLabelsResponse else { throw MockBehaviorDefaultError() }
        return try await detectLabelsResponse(input)
    }

    func detectModerationLabels(input: DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutput {
        guard let moderationLabelsResponse else { throw MockBehaviorDefaultError() }
        return try await moderationLabelsResponse(input)
    }

    func detectCelebrities(input: RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutput {
        guard let celebritiesResponse else { throw MockBehaviorDefaultError() }
        return try await celebritiesResponse(input)
    }

    func detectText(input: DetectTextInput) async throws -> DetectTextOutput {
        guard let detectTextResponse else { throw MockBehaviorDefaultError() }
        return try await detectTextResponse(input)
    }

    func detectFaces(input: DetectFacesInput) async throws -> DetectFacesOutput {
        guard let facesResponse else { throw MockBehaviorDefaultError() }
        return try await facesResponse(input)
    }

    func searchFacesByImage(input: SearchFacesByImageInput) async throws -> SearchFacesByImageOutput {
        guard let facesFromCollectionResponse else { throw MockBehaviorDefaultError() }
        return try await facesFromCollectionResponse(input)
    }

    func getRekognition() -> AWSRekognition.RekognitionClient {
        try! .init(region: "us-east-1")
    }
}

// MARK: Unused RekognitionClientProtocol Methods
extension MockRekognitionBehavior {
    func compareFaces(input: AWSRekognition.CompareFacesInput) async throws -> AWSRekognition.CompareFacesOutput { fatalError() }
    func copyProjectVersion(input: AWSRekognition.CopyProjectVersionInput) async throws -> AWSRekognition.CopyProjectVersionOutput { fatalError() }
    func createCollection(input: AWSRekognition.CreateCollectionInput) async throws -> AWSRekognition.CreateCollectionOutput { fatalError() }
    func createDataset(input: AWSRekognition.CreateDatasetInput) async throws -> AWSRekognition.CreateDatasetOutput { fatalError() }
    func createProject(input: AWSRekognition.CreateProjectInput) async throws -> AWSRekognition.CreateProjectOutput { fatalError() }
    func createProjectVersion(input: AWSRekognition.CreateProjectVersionInput) async throws -> AWSRekognition.CreateProjectVersionOutput { fatalError() }
    func createStreamProcessor(input: AWSRekognition.CreateStreamProcessorInput) async throws -> AWSRekognition.CreateStreamProcessorOutput { fatalError() }
    func deleteCollection(input: AWSRekognition.DeleteCollectionInput) async throws -> AWSRekognition.DeleteCollectionOutput { fatalError() }
    func deleteDataset(input: AWSRekognition.DeleteDatasetInput) async throws -> AWSRekognition.DeleteDatasetOutput { fatalError() }
    func deleteFaces(input: AWSRekognition.DeleteFacesInput) async throws -> AWSRekognition.DeleteFacesOutput { fatalError() }
    func deleteProject(input: AWSRekognition.DeleteProjectInput) async throws -> AWSRekognition.DeleteProjectOutput { fatalError() }
    func deleteProjectPolicy(input: AWSRekognition.DeleteProjectPolicyInput) async throws -> AWSRekognition.DeleteProjectPolicyOutput { fatalError() }
    func deleteProjectVersion(input: AWSRekognition.DeleteProjectVersionInput) async throws -> AWSRekognition.DeleteProjectVersionOutput { fatalError() }
    func deleteStreamProcessor(input: AWSRekognition.DeleteStreamProcessorInput) async throws -> AWSRekognition.DeleteStreamProcessorOutput { fatalError() }
    func describeCollection(input: AWSRekognition.DescribeCollectionInput) async throws -> AWSRekognition.DescribeCollectionOutput { fatalError() }
    func describeDataset(input: AWSRekognition.DescribeDatasetInput) async throws -> AWSRekognition.DescribeDatasetOutput { fatalError() }
    func describeProjects(input: AWSRekognition.DescribeProjectsInput) async throws -> AWSRekognition.DescribeProjectsOutput { fatalError() }
    func describeProjectVersions(input: AWSRekognition.DescribeProjectVersionsInput) async throws -> AWSRekognition.DescribeProjectVersionsOutput { fatalError() }
    func describeStreamProcessor(input: AWSRekognition.DescribeStreamProcessorInput) async throws -> AWSRekognition.DescribeStreamProcessorOutput { fatalError() }
    func detectCustomLabels(input: AWSRekognition.DetectCustomLabelsInput) async throws -> AWSRekognition.DetectCustomLabelsOutput { fatalError() }
    func detectProtectiveEquipment(input: AWSRekognition.DetectProtectiveEquipmentInput) async throws -> AWSRekognition.DetectProtectiveEquipmentOutput { fatalError() }
    func distributeDatasetEntries(input: AWSRekognition.DistributeDatasetEntriesInput) async throws -> AWSRekognition.DistributeDatasetEntriesOutput { fatalError() }
    func getCelebrityInfo(input: AWSRekognition.GetCelebrityInfoInput) async throws -> AWSRekognition.GetCelebrityInfoOutput { fatalError() }
    func getCelebrityRecognition(input: AWSRekognition.GetCelebrityRecognitionInput) async throws -> AWSRekognition.GetCelebrityRecognitionOutput { fatalError() }
    func getContentModeration(input: AWSRekognition.GetContentModerationInput) async throws -> AWSRekognition.GetContentModerationOutput { fatalError() }
    func getFaceDetection(input: AWSRekognition.GetFaceDetectionInput) async throws -> AWSRekognition.GetFaceDetectionOutput { fatalError() }
    func getFaceSearch(input: AWSRekognition.GetFaceSearchInput) async throws -> AWSRekognition.GetFaceSearchOutput { fatalError() }
    func getLabelDetection(input: AWSRekognition.GetLabelDetectionInput) async throws -> AWSRekognition.GetLabelDetectionOutput { fatalError() }
    func getPersonTracking(input: AWSRekognition.GetPersonTrackingInput) async throws -> AWSRekognition.GetPersonTrackingOutput { fatalError() }
    func getSegmentDetection(input: AWSRekognition.GetSegmentDetectionInput) async throws -> AWSRekognition.GetSegmentDetectionOutput { fatalError() }
    func getTextDetection(input: AWSRekognition.GetTextDetectionInput) async throws -> AWSRekognition.GetTextDetectionOutput { fatalError() }
    func indexFaces(input: AWSRekognition.IndexFacesInput) async throws -> AWSRekognition.IndexFacesOutput { fatalError() }
    func listCollections(input: AWSRekognition.ListCollectionsInput) async throws -> AWSRekognition.ListCollectionsOutput { fatalError() }
    func listDatasetEntries(input: AWSRekognition.ListDatasetEntriesInput) async throws -> AWSRekognition.ListDatasetEntriesOutput { fatalError() }
    func listDatasetLabels(input: AWSRekognition.ListDatasetLabelsInput) async throws -> AWSRekognition.ListDatasetLabelsOutput { fatalError() }
    func listFaces(input: AWSRekognition.ListFacesInput) async throws -> AWSRekognition.ListFacesOutput { fatalError() }
    func listProjectPolicies(input: AWSRekognition.ListProjectPoliciesInput) async throws -> AWSRekognition.ListProjectPoliciesOutput { fatalError() }
    func listStreamProcessors(input: AWSRekognition.ListStreamProcessorsInput) async throws -> AWSRekognition.ListStreamProcessorsOutput { fatalError() }
    func listTagsForResource(input: AWSRekognition.ListTagsForResourceInput) async throws -> AWSRekognition.ListTagsForResourceOutput { fatalError() }
    func putProjectPolicy(input: AWSRekognition.PutProjectPolicyInput) async throws -> AWSRekognition.PutProjectPolicyOutput { fatalError() }
    func recognizeCelebrities(input: AWSRekognition.RecognizeCelebritiesInput) async throws -> AWSRekognition.RecognizeCelebritiesOutput { fatalError() }
    func searchFaces(input: AWSRekognition.SearchFacesInput) async throws -> AWSRekognition.SearchFacesOutput { fatalError() }
    func startCelebrityRecognition(input: AWSRekognition.StartCelebrityRecognitionInput) async throws -> AWSRekognition.StartCelebrityRecognitionOutput { fatalError() }
    func startContentModeration(input: AWSRekognition.StartContentModerationInput) async throws -> AWSRekognition.StartContentModerationOutput { fatalError() }
    func startFaceDetection(input: AWSRekognition.StartFaceDetectionInput) async throws -> AWSRekognition.StartFaceDetectionOutput { fatalError() }
    func startFaceSearch(input: AWSRekognition.StartFaceSearchInput) async throws -> AWSRekognition.StartFaceSearchOutput { fatalError() }
    func startLabelDetection(input: AWSRekognition.StartLabelDetectionInput) async throws -> AWSRekognition.StartLabelDetectionOutput { fatalError() }
    func startPersonTracking(input: AWSRekognition.StartPersonTrackingInput) async throws -> AWSRekognition.StartPersonTrackingOutput { fatalError() }
    func startProjectVersion(input: AWSRekognition.StartProjectVersionInput) async throws -> AWSRekognition.StartProjectVersionOutput { fatalError() }
    func startSegmentDetection(input: AWSRekognition.StartSegmentDetectionInput) async throws -> AWSRekognition.StartSegmentDetectionOutput { fatalError() }
    func startStreamProcessor(input: AWSRekognition.StartStreamProcessorInput) async throws -> AWSRekognition.StartStreamProcessorOutput { fatalError() }
    func startTextDetection(input: AWSRekognition.StartTextDetectionInput) async throws -> AWSRekognition.StartTextDetectionOutput { fatalError() }
    func stopProjectVersion(input: AWSRekognition.StopProjectVersionInput) async throws -> AWSRekognition.StopProjectVersionOutput { fatalError() }
    func stopStreamProcessor(input: AWSRekognition.StopStreamProcessorInput) async throws -> AWSRekognition.StopStreamProcessorOutput { fatalError() }
    func tagResource(input: AWSRekognition.TagResourceInput) async throws -> AWSRekognition.TagResourceOutput { fatalError() }
    func untagResource(input: AWSRekognition.UntagResourceInput) async throws -> AWSRekognition.UntagResourceOutput { fatalError() }
    func updateDatasetEntries(input: AWSRekognition.UpdateDatasetEntriesInput) async throws -> AWSRekognition.UpdateDatasetEntriesOutput { fatalError() }
    func updateStreamProcessor(input: AWSRekognition.UpdateStreamProcessorInput) async throws -> AWSRekognition.UpdateStreamProcessorOutput { fatalError() }
    func associateFaces(input: AWSRekognition.AssociateFacesInput) async throws -> AWSRekognition.AssociateFacesOutput { fatalError() }
    func createFaceLivenessSession(input: AWSRekognition.CreateFaceLivenessSessionInput) async throws -> AWSRekognition.CreateFaceLivenessSessionOutput { fatalError() }
    func createUser(input: AWSRekognition.CreateUserInput) async throws -> AWSRekognition.CreateUserOutput { fatalError() }
    func deleteUser(input: AWSRekognition.DeleteUserInput) async throws -> AWSRekognition.DeleteUserOutput { fatalError() }
    func disassociateFaces(input: AWSRekognition.DisassociateFacesInput) async throws -> AWSRekognition.DisassociateFacesOutput { fatalError() }
    func getFaceLivenessSessionResults(input: AWSRekognition.GetFaceLivenessSessionResultsInput) async throws -> AWSRekognition.GetFaceLivenessSessionResultsOutput { fatalError() }
    func listUsers(input: AWSRekognition.ListUsersInput) async throws -> AWSRekognition.ListUsersOutput { fatalError() }
    func searchUsers(input: AWSRekognition.SearchUsersInput) async throws -> AWSRekognition.SearchUsersOutput { fatalError() }
    func searchUsersByImage(input: AWSRekognition.SearchUsersByImageInput) async throws -> AWSRekognition.SearchUsersByImageOutput { fatalError() }
    func getMediaAnalysisJob(input: AWSRekognition.GetMediaAnalysisJobInput) async throws -> AWSRekognition.GetMediaAnalysisJobOutput {
        fatalError()
    }

    func listMediaAnalysisJobs(input: AWSRekognition.ListMediaAnalysisJobsInput) async throws -> AWSRekognition.ListMediaAnalysisJobsOutput {
        fatalError()
    }

    func startMediaAnalysisJob(input: AWSRekognition.StartMediaAnalysisJobInput) async throws -> AWSRekognition.StartMediaAnalysisJobOutput {
        fatalError()
    }
}
