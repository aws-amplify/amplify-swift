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
    var detectLabelsResponse: ((DetectLabelsInput) async throws -> DetectLabelsOutputResponse)? = nil
    var moderationLabelsResponse: ((DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutputResponse)? = nil
    var celebritiesResponse: ((RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutputResponse)? = nil
    var detectTextResponse: ((DetectTextInput) async throws -> DetectTextOutputResponse)? = nil
    var facesResponse: ((DetectFacesInput) async throws -> DetectFacesOutputResponse)? = nil
    var facesFromCollectionResponse: ((SearchFacesByImageInput) async throws -> SearchFacesByImageOutputResponse)? = nil

    func detectLabels(input: DetectLabelsInput) async throws -> DetectLabelsOutputResponse {
        guard let detectLabelsResponse else { throw MockBehaviorDefaultError() }
        return try await detectLabelsResponse(input)
    }

    func detectModerationLabels(input: DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutputResponse {
        guard let moderationLabelsResponse else { throw MockBehaviorDefaultError() }
        return try await moderationLabelsResponse(input)
    }

    func detectCelebrities(input: RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutputResponse {
        guard let celebritiesResponse else { throw MockBehaviorDefaultError() }
        return try await celebritiesResponse(input)
    }

    func detectText(input: DetectTextInput) async throws -> DetectTextOutputResponse {
        guard let detectTextResponse else { throw MockBehaviorDefaultError() }
        return try await detectTextResponse(input)
    }

    func detectFaces(input: DetectFacesInput) async throws -> DetectFacesOutputResponse {
        guard let facesResponse else { throw MockBehaviorDefaultError() }
        return try await facesResponse(input)
    }

    func searchFacesByImage(input: SearchFacesByImageInput) async throws -> SearchFacesByImageOutputResponse {
        guard let facesFromCollectionResponse else { throw MockBehaviorDefaultError() }
        return try await facesFromCollectionResponse(input)
    }

    func getRekognition() -> AWSRekognition.RekognitionClient {
        try! .init(region: "us-east-1")
    }
}

// MARK: Unused RekognitionClientProtocol Methods
extension MockRekognitionBehavior {
    func compareFaces(input: AWSRekognition.CompareFacesInput) async throws -> AWSRekognition.CompareFacesOutputResponse { fatalError() }
    func copyProjectVersion(input: AWSRekognition.CopyProjectVersionInput) async throws -> AWSRekognition.CopyProjectVersionOutputResponse { fatalError() }
    func createCollection(input: AWSRekognition.CreateCollectionInput) async throws -> AWSRekognition.CreateCollectionOutputResponse { fatalError() }
    func createDataset(input: AWSRekognition.CreateDatasetInput) async throws -> AWSRekognition.CreateDatasetOutputResponse { fatalError() }
    func createProject(input: AWSRekognition.CreateProjectInput) async throws -> AWSRekognition.CreateProjectOutputResponse { fatalError() }
    func createProjectVersion(input: AWSRekognition.CreateProjectVersionInput) async throws -> AWSRekognition.CreateProjectVersionOutputResponse { fatalError() }
    func createStreamProcessor(input: AWSRekognition.CreateStreamProcessorInput) async throws -> AWSRekognition.CreateStreamProcessorOutputResponse { fatalError() }
    func deleteCollection(input: AWSRekognition.DeleteCollectionInput) async throws -> AWSRekognition.DeleteCollectionOutputResponse { fatalError() }
    func deleteDataset(input: AWSRekognition.DeleteDatasetInput) async throws -> AWSRekognition.DeleteDatasetOutputResponse { fatalError() }
    func deleteFaces(input: AWSRekognition.DeleteFacesInput) async throws -> AWSRekognition.DeleteFacesOutputResponse { fatalError() }
    func deleteProject(input: AWSRekognition.DeleteProjectInput) async throws -> AWSRekognition.DeleteProjectOutputResponse { fatalError() }
    func deleteProjectPolicy(input: AWSRekognition.DeleteProjectPolicyInput) async throws -> AWSRekognition.DeleteProjectPolicyOutputResponse { fatalError() }
    func deleteProjectVersion(input: AWSRekognition.DeleteProjectVersionInput) async throws -> AWSRekognition.DeleteProjectVersionOutputResponse { fatalError() }
    func deleteStreamProcessor(input: AWSRekognition.DeleteStreamProcessorInput) async throws -> AWSRekognition.DeleteStreamProcessorOutputResponse { fatalError() }
    func describeCollection(input: AWSRekognition.DescribeCollectionInput) async throws -> AWSRekognition.DescribeCollectionOutputResponse { fatalError() }
    func describeDataset(input: AWSRekognition.DescribeDatasetInput) async throws -> AWSRekognition.DescribeDatasetOutputResponse { fatalError() }
    func describeProjects(input: AWSRekognition.DescribeProjectsInput) async throws -> AWSRekognition.DescribeProjectsOutputResponse { fatalError() }
    func describeProjectVersions(input: AWSRekognition.DescribeProjectVersionsInput) async throws -> AWSRekognition.DescribeProjectVersionsOutputResponse { fatalError() }
    func describeStreamProcessor(input: AWSRekognition.DescribeStreamProcessorInput) async throws -> AWSRekognition.DescribeStreamProcessorOutputResponse { fatalError() }
    func detectCustomLabels(input: AWSRekognition.DetectCustomLabelsInput) async throws -> AWSRekognition.DetectCustomLabelsOutputResponse { fatalError() }
    func detectProtectiveEquipment(input: AWSRekognition.DetectProtectiveEquipmentInput) async throws -> AWSRekognition.DetectProtectiveEquipmentOutputResponse { fatalError() }
    func distributeDatasetEntries(input: AWSRekognition.DistributeDatasetEntriesInput) async throws -> AWSRekognition.DistributeDatasetEntriesOutputResponse { fatalError() }
    func getCelebrityInfo(input: AWSRekognition.GetCelebrityInfoInput) async throws -> AWSRekognition.GetCelebrityInfoOutputResponse { fatalError() }
    func getCelebrityRecognition(input: AWSRekognition.GetCelebrityRecognitionInput) async throws -> AWSRekognition.GetCelebrityRecognitionOutputResponse { fatalError() }
    func getContentModeration(input: AWSRekognition.GetContentModerationInput) async throws -> AWSRekognition.GetContentModerationOutputResponse { fatalError() }
    func getFaceDetection(input: AWSRekognition.GetFaceDetectionInput) async throws -> AWSRekognition.GetFaceDetectionOutputResponse { fatalError() }
    func getFaceSearch(input: AWSRekognition.GetFaceSearchInput) async throws -> AWSRekognition.GetFaceSearchOutputResponse { fatalError() }
    func getLabelDetection(input: AWSRekognition.GetLabelDetectionInput) async throws -> AWSRekognition.GetLabelDetectionOutputResponse { fatalError() }
    func getPersonTracking(input: AWSRekognition.GetPersonTrackingInput) async throws -> AWSRekognition.GetPersonTrackingOutputResponse { fatalError() }
    func getSegmentDetection(input: AWSRekognition.GetSegmentDetectionInput) async throws -> AWSRekognition.GetSegmentDetectionOutputResponse { fatalError() }
    func getTextDetection(input: AWSRekognition.GetTextDetectionInput) async throws -> AWSRekognition.GetTextDetectionOutputResponse { fatalError() }
    func indexFaces(input: AWSRekognition.IndexFacesInput) async throws -> AWSRekognition.IndexFacesOutputResponse { fatalError() }
    func listCollections(input: AWSRekognition.ListCollectionsInput) async throws -> AWSRekognition.ListCollectionsOutputResponse { fatalError() }
    func listDatasetEntries(input: AWSRekognition.ListDatasetEntriesInput) async throws -> AWSRekognition.ListDatasetEntriesOutputResponse { fatalError() }
    func listDatasetLabels(input: AWSRekognition.ListDatasetLabelsInput) async throws -> AWSRekognition.ListDatasetLabelsOutputResponse { fatalError() }
    func listFaces(input: AWSRekognition.ListFacesInput) async throws -> AWSRekognition.ListFacesOutputResponse { fatalError() }
    func listProjectPolicies(input: AWSRekognition.ListProjectPoliciesInput) async throws -> AWSRekognition.ListProjectPoliciesOutputResponse { fatalError() }
    func listStreamProcessors(input: AWSRekognition.ListStreamProcessorsInput) async throws -> AWSRekognition.ListStreamProcessorsOutputResponse { fatalError() }
    func listTagsForResource(input: AWSRekognition.ListTagsForResourceInput) async throws -> AWSRekognition.ListTagsForResourceOutputResponse { fatalError() }
    func putProjectPolicy(input: AWSRekognition.PutProjectPolicyInput) async throws -> AWSRekognition.PutProjectPolicyOutputResponse { fatalError() }
    func recognizeCelebrities(input: AWSRekognition.RecognizeCelebritiesInput) async throws -> AWSRekognition.RecognizeCelebritiesOutputResponse { fatalError() }
    func searchFaces(input: AWSRekognition.SearchFacesInput) async throws -> AWSRekognition.SearchFacesOutputResponse { fatalError() }
    func startCelebrityRecognition(input: AWSRekognition.StartCelebrityRecognitionInput) async throws -> AWSRekognition.StartCelebrityRecognitionOutputResponse { fatalError() }
    func startContentModeration(input: AWSRekognition.StartContentModerationInput) async throws -> AWSRekognition.StartContentModerationOutputResponse { fatalError() }
    func startFaceDetection(input: AWSRekognition.StartFaceDetectionInput) async throws -> AWSRekognition.StartFaceDetectionOutputResponse { fatalError() }
    func startFaceSearch(input: AWSRekognition.StartFaceSearchInput) async throws -> AWSRekognition.StartFaceSearchOutputResponse { fatalError() }
    func startLabelDetection(input: AWSRekognition.StartLabelDetectionInput) async throws -> AWSRekognition.StartLabelDetectionOutputResponse { fatalError() }
    func startPersonTracking(input: AWSRekognition.StartPersonTrackingInput) async throws -> AWSRekognition.StartPersonTrackingOutputResponse { fatalError() }
    func startProjectVersion(input: AWSRekognition.StartProjectVersionInput) async throws -> AWSRekognition.StartProjectVersionOutputResponse { fatalError() }
    func startSegmentDetection(input: AWSRekognition.StartSegmentDetectionInput) async throws -> AWSRekognition.StartSegmentDetectionOutputResponse { fatalError() }
    func startStreamProcessor(input: AWSRekognition.StartStreamProcessorInput) async throws -> AWSRekognition.StartStreamProcessorOutputResponse { fatalError() }
    func startTextDetection(input: AWSRekognition.StartTextDetectionInput) async throws -> AWSRekognition.StartTextDetectionOutputResponse { fatalError() }
    func stopProjectVersion(input: AWSRekognition.StopProjectVersionInput) async throws -> AWSRekognition.StopProjectVersionOutputResponse { fatalError() }
    func stopStreamProcessor(input: AWSRekognition.StopStreamProcessorInput) async throws -> AWSRekognition.StopStreamProcessorOutputResponse { fatalError() }
    func tagResource(input: AWSRekognition.TagResourceInput) async throws -> AWSRekognition.TagResourceOutputResponse { fatalError() }
    func untagResource(input: AWSRekognition.UntagResourceInput) async throws -> AWSRekognition.UntagResourceOutputResponse { fatalError() }
    func updateDatasetEntries(input: AWSRekognition.UpdateDatasetEntriesInput) async throws -> AWSRekognition.UpdateDatasetEntriesOutputResponse { fatalError() }
    func updateStreamProcessor(input: AWSRekognition.UpdateStreamProcessorInput) async throws -> AWSRekognition.UpdateStreamProcessorOutputResponse { fatalError() }
    func associateFaces(input: AWSRekognition.AssociateFacesInput) async throws -> AWSRekognition.AssociateFacesOutputResponse { fatalError() }

    func createFaceLivenessSession(input: AWSRekognition.CreateFaceLivenessSessionInput) async throws -> AWSRekognition.CreateFaceLivenessSessionOutputResponse { fatalError() }

    func createUser(input: AWSRekognition.CreateUserInput) async throws -> AWSRekognition.CreateUserOutputResponse { fatalError() }

    func deleteUser(input: AWSRekognition.DeleteUserInput) async throws -> AWSRekognition.DeleteUserOutputResponse { fatalError() }

    func disassociateFaces(input: AWSRekognition.DisassociateFacesInput) async throws -> AWSRekognition.DisassociateFacesOutputResponse { fatalError() }

    func getFaceLivenessSessionResults(input: AWSRekognition.GetFaceLivenessSessionResultsInput) async throws -> AWSRekognition.GetFaceLivenessSessionResultsOutputResponse { fatalError() }

    func listUsers(input: AWSRekognition.ListUsersInput) async throws -> AWSRekognition.ListUsersOutputResponse { fatalError() }

    func searchUsers(input: AWSRekognition.SearchUsersInput) async throws -> AWSRekognition.SearchUsersOutputResponse { fatalError() }

    func searchUsersByImage(input: AWSRekognition.SearchUsersByImageInput) async throws -> AWSRekognition.SearchUsersByImageOutputResponse { fatalError() }
}
