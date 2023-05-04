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
       return try await awsTextract.detectDocumentText(input: request)
    }

    func analyzeDocument(
        image: URL,
        features: [String]
    ) async throws -> Predictions.Identify.DocumentText.Result {
        let imageData: Data
        do {
            imageData = try Data(contentsOf: image)
        } catch {
            throw PredictionsError.client(.imageNotFound)
        }

        let document = TextractClientTypes.Document(bytes: imageData)
        let featureTypes = features.compactMap(
            TextractClientTypes.FeatureType.init(rawValue:)
        )
        let request = AnalyzeDocumentInput(
            document: document,
            featureTypes: featureTypes
        )

        let documentResult: AnalyzeDocumentOutputResponse
        do {
            documentResult = try await awsTextract.analyzeDocument(input: request)
        } catch let error as AnalyzeDocumentOutputError {
            throw ServiceErrorMapping.analyzeDocument.map(error)
        } catch {
            throw PredictionsError.unexpectedServiceErrorType(error)
        }

        let textResult = IdentifyTextResultTransformers.processText(documentResult.blocks ?? [])
        return textResult
    }
}
