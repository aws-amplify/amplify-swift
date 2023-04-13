//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
import Foundation

protocol AWSRekognitionServiceBehavior {

    typealias RekognitionServiceEventHandler = (RekognitionServiceEvent) -> Void
    typealias RekognitionServiceEvent = PredictionsEvent<IdentifyResult, PredictionsError>

    func detectLabels(
        image: URL,
        type: LabelType
    ) async throws -> IdentifyLabelsResult

    func detectCelebrities(
        image: URL
    ) async throws -> IdentifyCelebritiesResult

    func detectDocumentText(
        image: URL,
        format: TextFormatType
    ) async throws -> IdentifyDocumentTextResult

    func detectPlainText(
        image: URL
    ) async throws -> IdentifyTextResult

    func detectEntities(
        image: URL
    ) async throws -> IdentifyEntitiesResult

    func detectEntitiesCollection(
        image: URL,
        collectionID: String
    ) async throws -> IdentifyEntityMatchesResult
}
