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
    func detectLabels(
        image: URL,
        type: Predictions.LabelType
    ) async throws -> Predictions.Identify.Labels.Result

    func detectCelebrities(
        image: URL
    ) async throws -> Predictions.Identify.Celebrities.Result

    func detectDocumentText(
        image: URL,
        format: Predictions.TextFormatType
    ) async throws -> Predictions.Identify.DocumentText.Result

    func detectPlainText(
        image: URL
    ) async throws -> Predictions.Identify.Text.Result

    func detectEntities(
        image: URL
    ) async throws -> Predictions.Identify.Entities.Result

    func detectEntitiesCollection(
        image: URL,
        collectionID: String
    ) async throws -> Predictions.Identify.EntityMatches.Result
}
