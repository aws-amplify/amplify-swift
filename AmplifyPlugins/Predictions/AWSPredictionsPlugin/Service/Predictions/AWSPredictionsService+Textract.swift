//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract
import Amplify
import Foundation

extension AWSPredictionsService: AWSTextractServiceBehavior {
    func detectDocumentText(
        image: Data
    ) async throws -> DetectDocumentTextOutputResponse {
        let document = TextractClientTypes.Document(bytes: image)
        let request = DetectDocumentTextInput(document: document)
       return try await awsTextract.detectDocumentText(request: request)
    }

    func analyzeDocument(
        image: URL,
        features: [String]
    ) async throws -> Predictions.Identify.DocumentText.Result {
        let imageData: Data
        do {
            imageData = try Data(contentsOf: image)
        } catch {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.imageNotFound.errorDescription,
                AWSRekognitionErrorMessage.imageNotFound.recoverySuggestion
            )
        }

        let document = TextractClientTypes.Document(bytes: imageData)
        let featureTypes = features.compactMap(TextractClientTypes.FeatureType.init(rawValue:))

        let request = AnalyzeDocumentInput(
            document: document,
            featureTypes: featureTypes
        )

        let documentResult: AnalyzeDocumentOutputResponse
        do {
            documentResult = try await awsTextract.analyzeDocument(request: request)
        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let blocks = documentResult.blocks else {
            throw PredictionsError.network(
                "No result was found.",
                "Please make sure the image integrity is maintained before sending"
            )
        }

        let textResult = IdentifyTextResultTransformers.processText(blocks)
        return textResult
    }
}
