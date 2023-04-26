//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
import AWSTextract
import Foundation

// swiftlint:disable file_length
extension AWSPredictionsService: AWSRekognitionServiceBehavior {
    func detectLabels(
        image: URL,
        type: Predictions.LabelType
    ) async throws -> Predictions.Identify.Labels.Result  {
        let imageData = try dataFromImage(url: image)

        switch type {
        case .labels:
            let labelsResult: DetectLabelsOutputResponse
            do {
                labelsResult = try await detectRekognitionLabels(image: imageData)
            } catch {
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                throw PredictionsError.network(
                    predictionsErrorString.errorDescription,
                    predictionsErrorString.recoverySuggestion
                )
            }
            
            guard let labels = labelsResult.labels else {
                throw PredictionsError.network(
                    AWSRekognitionErrorMessage.noResultFound.errorDescription,
                    AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
                )
            }

            let newLabels = IdentifyLabelsResultTransformers.processLabels(labels)
            return Predictions.Identify.Labels.Result(labels: newLabels, unsafeContent: nil)
        case .moderation:
            let moderationLabelsResult: DetectModerationLabelsOutputResponse
            do {
                moderationLabelsResult = try await detectModerationLabels(image: imageData)
            } catch {
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                throw PredictionsError.network(
                    predictionsErrorString.errorDescription,
                    predictionsErrorString.recoverySuggestion
                )
            }

            guard let moderationRekognitionlabels = moderationLabelsResult.moderationLabels else {
                throw PredictionsError.network(
                    AWSRekognitionErrorMessage.noResultFound.errorDescription,
                    AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
                )
            }

            let unsafeContent: Bool = !moderationRekognitionlabels.isEmpty

            let labels = IdentifyLabelsResultTransformers.processModerationLabels(moderationRekognitionlabels)
            return Predictions.Identify.Labels.Result(labels: labels, unsafeContent: unsafeContent)
        case .all:
            return try await detectAllLabels(image: imageData)
        }
    }

    func detectCelebrities(
        image: URL
    ) async throws -> Predictions.Identify.Celebrities.Result {
        let imageData = try dataFromImage(url: image)

        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let request = RecognizeCelebritiesInput(image: rekognitionImage)
        let celebritiesResult: RecognizeCelebritiesOutputResponse

        do {
            celebritiesResult = try await awsRekognition.detectCelebrities(request: request)
        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let celebrities = celebritiesResult.celebrityFaces else {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.noResultFound.errorDescription,
                AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
            )
        }


        let newCelebs = IdentifyCelebritiesResultTransformers.processCelebs(celebrities)
        return Predictions.Identify.Celebrities.Result(celebrities: newCelebs)
    }

    func detectEntitiesCollection(
        image: URL,
        collectionID: String
    ) async throws -> Predictions.Identify.EntityMatches.Result {
        guard !collectionID.isEmpty else {
            throw NSError(domain: "", code: -1)
        }

        let imageData = try dataFromImage(url: image)

        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let maxFaces = predictionsConfig.identify.identifyEntities?.maxEntities
            .map(Int.init) ?? 50

        let request = SearchFacesByImageInput(
            collectionId: collectionID,
            image: rekognitionImage,
            maxFaces: maxFaces
        )

        let facesFromCollectionResult: SearchFacesByImageOutputResponse

        do {
            facesFromCollectionResult = try await awsRekognition.detectFacesFromCollection(request: request)
        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let faces = facesFromCollectionResult.faceMatches else {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.noResultFound.errorDescription,
                AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
            )
        }

        let faceMatches = IdentifyEntitiesResultTransformers.processCollectionFaces(faces)
        return Predictions.Identify.EntityMatches.Result(entities: faceMatches)
    }

    func detectEntities(
        image: URL
    ) async throws -> Predictions.Identify.Entities.Result {
        let imageData = try dataFromImage(url: image)

        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let request = DetectFacesInput(image: rekognitionImage)

        let facesResult: DetectFacesOutputResponse
        do {
            facesResult = try await awsRekognition.detectFaces(request: request)
        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let faces = facesResult.faceDetails else {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.noResultFound.errorDescription,
                AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
            )
        }

        let newFaces = IdentifyEntitiesResultTransformers.processFaces(faces)
        return Predictions.Identify.Entities.Result(entities: newFaces)
    }


    func detectPlainText(image: URL) async throws -> Predictions.Identify.Text.Result {
        let imageData = try dataFromImage(url: image)

        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let request = DetectTextInput(image: rekognitionImage)

        let textResult: DetectTextOutputResponse
        do {
            textResult = try await awsRekognition.detectText(request: request)
        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let rekognitionTextDetections = textResult.textDetections else {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.noResultFound.errorDescription,
                AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
            )
        }

        let identifyTextResult = IdentifyTextResultTransformers.processText(rekognitionTextDetections)

        // if limit of words is under 50 return rekognition response
        // otherwise call textract because their limit is higher
        if let words = identifyTextResult.words, words.count < rekognitionWordLimit {
            return identifyTextResult
        } else {

            let documentTextResult: DetectDocumentTextOutputResponse
            do {
                documentTextResult = try await detectDocumentText(image: imageData)
            } catch {
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                throw PredictionsError.network(
                    predictionsErrorString.errorDescription,
                    predictionsErrorString.recoverySuggestion
                )
            }

            guard let textractTextDetections = documentTextResult.blocks else {
                throw PredictionsError.network(
                    AWSRekognitionErrorMessage.noResultFound.errorDescription,
                    AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
                )
            }

            if rekognitionTextDetections.count > textractTextDetections.count {
                return identifyTextResult
            } else {
                let textractResult = IdentifyTextResultTransformers.processText(textractTextDetections)
                return textractResult
            }
        }
    }

    func detectDocumentText(
        image: URL,
        format: Predictions.TextFormatType
    ) async throws -> Predictions.Identify.DocumentText.Result {
        return try await analyzeDocument(
            image: image,
            features: format.textractServiceFormatType
        )
    }




    private func detectTextRekognition(
        image: URL
    ) async throws -> Predictions.Identify.Text.Result {
        let imageData: Data
        do {
            imageData = try Data(contentsOf: image)
        } catch {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.imageNotFound.errorDescription,
                AWSRekognitionErrorMessage.imageNotFound.recoverySuggestion
            )
        }

        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let request = DetectTextInput(image: rekognitionImage)

        let textResult: DetectTextOutputResponse
        do {
            textResult = try await awsRekognition.detectText(request: request)
        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let rekognitionTextDetections = textResult.textDetections else {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.noResultFound.errorDescription,
                AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
            )
        }

        let identifyTextResult = IdentifyTextResultTransformers.processText(rekognitionTextDetections)

        // if limit of words is under 50 return rekognition response
        // otherwise call textract because their limit is higher
        if let words = identifyTextResult.words, words.count < rekognitionWordLimit {
            return identifyTextResult
        } else {

            let documentTextResult: DetectDocumentTextOutputResponse
            do {
                documentTextResult = try await detectDocumentText(image: imageData)
            } catch {
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                throw PredictionsError.network(
                    predictionsErrorString.errorDescription,
                    predictionsErrorString.recoverySuggestion
                )
            }

            guard let textractTextDetections = documentTextResult.blocks else {
                throw PredictionsError.network(
                    AWSRekognitionErrorMessage.noResultFound.errorDescription,
                    AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
                )
            }

            if rekognitionTextDetections.count > textractTextDetections.count {
                return identifyTextResult
            } else {
                let textractResult = IdentifyTextResultTransformers.processText(textractTextDetections)
                fatalError() // TODO: Combine types
//                return textractResult
            }
        }
    }

    private func detectModerationLabels(
        image: Data
    ) async throws -> DetectModerationLabelsOutputResponse {
        let image = RekognitionClientTypes.Image(bytes: image)
        let request = DetectModerationLabelsInput(
            image: image
        )
        // TODO: What are we doing with this onEvent handler???
        return try await awsRekognition.detectModerationLabels(request: request)
    }

    private func detectRekognitionLabels(
        image: Data
    ) async throws -> DetectLabelsOutputResponse {
        let image = RekognitionClientTypes.Image(bytes: image)
        let request = DetectLabelsInput(
            image: image
        )
        // TODO: What are we doing with this onEvent handler???
        return try await awsRekognition.detectLabels(request: request)
    }

    private func detectAllLabels(image: Data) async throws -> Predictions.Identify.Labels.Result {
        let labelsResult: DetectLabelsOutputResponse
        do {
            labelsResult = try await detectRekognitionLabels(image: image) //, onEvent: { _ in })

        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let labels = labelsResult.labels else {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.noResultFound.errorDescription,
                AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
            )
        }

        let allLabels = IdentifyLabelsResultTransformers.processLabels(labels)

        let moderationLabelsResult: DetectModerationLabelsOutputResponse
        do {
             moderationLabelsResult = try await detectModerationLabels(image: image)
        } catch {
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
            throw PredictionsError.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion
            )
        }

        guard let moderationRekognitionLabels = moderationLabelsResult.moderationLabels else {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.noResultFound.errorDescription,
                AWSRekognitionErrorMessage.noResultFound.recoverySuggestion
            )
        }

        let unsafeContent = !moderationRekognitionLabels.isEmpty

        return Predictions.Identify.Labels.Result(labels: allLabels, unsafeContent: unsafeContent)
    }

    private func dataFromImage(url: URL) throws -> Data {
        let imageData: Data
        do {
            imageData = try Data(contentsOf: url)
        } catch {
            throw PredictionsError.network(
                AWSRekognitionErrorMessage.imageNotFound.errorDescription,
                AWSRekognitionErrorMessage.imageNotFound.recoverySuggestion
            )
        }
        return imageData
    }
}
