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
            do {
                let labelsResult = try await detectLabels(image: imageData)
                let newLabels = IdentifyLabelsResultTransformers.processLabels(labelsResult.labels ?? [])
                return Predictions.Identify.Labels.Result(labels: newLabels, unsafeContent: nil)
            } catch let error as DetectLabelsOutputError {
                throw ServiceErrorMapping.detectLabels.map(error)
            } catch {
                throw PredictionsError.unexpectedServiceErrorType(error)
            }
        case .moderation:
            do {
                let moderationLabels = try await detectModerationLabels(image: imageData).moderationLabels ?? []
                let unsafeContent = !moderationLabels.isEmpty
                let labels = IdentifyLabelsResultTransformers.processModerationLabels(moderationLabels)
                return Predictions.Identify.Labels.Result(labels: labels, unsafeContent: unsafeContent)
            } catch let error as DetectModerationLabelsOutputError {
                throw ServiceErrorMapping.detectModerationLabels.map(error)
            }
            catch {
                throw PredictionsError.unexpectedServiceErrorType(error)
            }

        case .all:
            return try await detectAllLabels(image: imageData)
        default:
            throw PredictionsError.client(
                .init(
                    description: "Unsupported LabelType: \(type)",
                    recoverySuggestion: "This shouldn't happen. Please report a bug to Amplify Swift"
                )
            )
        }
    }

    func detectCelebrities(
        image: URL
    ) async throws -> Predictions.Identify.Celebrities.Result {
        let imageData = try dataFromImage(url: image)
        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let input = RecognizeCelebritiesInput(image: rekognitionImage)

        do {
            let celebrities = try await awsRekognition
                .recognizeCelebrities(input: input).celebrityFaces ?? []

            let newCelebs = IdentifyCelebritiesResultTransformers.processCelebs(celebrities)
            return Predictions.Identify.Celebrities.Result(celebrities: newCelebs)
        } catch let error as RecognizeCelebritiesOutputError {
            throw ServiceErrorMapping.detectCelebrities.map(error)
        } catch {
            throw PredictionsError.unexpectedServiceErrorType(error)
        }
    }

    func detectEntitiesCollection(
        image: URL,
        collectionID: String
    ) async throws -> Predictions.Identify.EntityMatches.Result {
        let imageData = try dataFromImage(url: image)
        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let maxFaces = predictionsConfig.identify.identifyEntities?.maxEntities
            .map(Int.init) ?? 50

        let input = SearchFacesByImageInput(
            collectionId: collectionID,
            image: rekognitionImage,
            maxFaces: maxFaces
        )

        do {
            let faces = try await awsRekognition
                .searchFacesByImage(input: input).faceMatches ?? []
            let faceMatches = IdentifyEntitiesResultTransformers.processCollectionFaces(faces)
            return Predictions.Identify.EntityMatches.Result(entities: faceMatches)
        } catch let error as SearchFacesByImageOutputError {
            throw ServiceErrorMapping.searchFacesByImage.map(error)
        } catch {
            throw PredictionsError.unexpectedServiceErrorType(error)
        }
    }

    func detectEntities(
        image: URL
    ) async throws -> Predictions.Identify.Entities.Result {
        let imageData = try dataFromImage(url: image)
        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let input = DetectFacesInput(image: rekognitionImage)

        do {
            let faces = try await awsRekognition.detectFaces(input: input).faceDetails ?? []
            let newFaces = IdentifyEntitiesResultTransformers.processFaces(faces)
            return Predictions.Identify.Entities.Result(entities: newFaces)
        } catch let error as DetectFacesOutputError {
            throw ServiceErrorMapping.detectFaces.map(error)
        } catch {
            throw PredictionsError.unknownServiceError(error)
        }
    }


    func detectPlainText(image: URL) async throws -> Predictions.Identify.Text.Result {
        let imageData = try dataFromImage(url: image)
        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let request = DetectTextInput(image: rekognitionImage)
        let textResult: DetectTextOutputResponse

        do {
            textResult = try await awsRekognition.detectText(input: request)
        } catch let error as DetectTextOutputError {
            throw ServiceErrorMapping.detectText.map(error)
        } catch {
            throw PredictionsError.unexpectedServiceErrorType(error)
        }

        let rekognitionTextDetections = textResult.textDetections ?? []
        let identifyTextResult = IdentifyTextResultTransformers.processText(
            rekognitionTextDetections
        )

        // if limit of words is under 50 return rekognition response
        // otherwise call textract because their limit is higher
        if let words = identifyTextResult.words, words.count < rekognitionWordLimit {
            return identifyTextResult
        } else {
            let documentTextResult: DetectDocumentTextOutputResponse
            do {
                documentTextResult = try await detectDocumentText(image: imageData)
            } catch let error as DetectDocumentTextOutputError {
                throw ServiceErrorMapping.detectDocumentText.map(error)
            } catch {
                throw PredictionsError.unexpectedServiceErrorType(error)
            }

            let textractTextDetections = documentTextResult.blocks ?? []

            if rekognitionTextDetections.count > textractTextDetections.count {
                return identifyTextResult
            } else {
                let textractResult = IdentifyTextResultTransformers.processText(
                    textractTextDetections
                )

                let identifyTextResult = Predictions.Identify.Text.Result(
                    fullText: textractResult.fullText,
                    words: textractResult.words,
                    rawLineText: textractResult.rawLineText,
                    identifiedLines: textractResult.identifiedLines
                )

                return identifyTextResult
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
            throw PredictionsError.client(.imageNotFound)
        }

        let rekognitionImage = RekognitionClientTypes.Image(bytes: imageData)
        let request = DetectTextInput(image: rekognitionImage)

        let textResult: DetectTextOutputResponse
        do {
            textResult = try await awsRekognition.detectText(input: request)
        } catch let error as DetectTextOutputError {
            throw ServiceErrorMapping.detectText.map(error)
        } catch {
            throw PredictionsError.unexpectedServiceErrorType(error)
        }

        let rekognitionTextDetections = textResult.textDetections ?? []

        let identifyTextResult = IdentifyTextResultTransformers.processText(
            rekognitionTextDetections
        )

        // if limit of words is under 50 return rekognition response
        // otherwise call textract because their limit is higher
        if let words = identifyTextResult.words, words.count < rekognitionWordLimit {
            return identifyTextResult
        } else {
            let documentTextResult: DetectDocumentTextOutputResponse
            do {
                documentTextResult = try await detectDocumentText(image: imageData)
            } catch let error as DetectDocumentTextOutputError {
                throw ServiceErrorMapping.detectDocumentText.map(error)
            } catch {
                throw PredictionsError.unexpectedServiceErrorType(error)
            }

            let textractTextDetections = documentTextResult.blocks ?? []

            if rekognitionTextDetections.count > textractTextDetections.count {
                return identifyTextResult
            } else {
                let textractResult = IdentifyTextResultTransformers.processText(textractTextDetections)
                let identifyTextResult = Predictions.Identify.Text.Result(
                    fullText: textractResult.fullText,
                    words: textractResult.words,
                    rawLineText: textractResult.rawLineText,
                    identifiedLines: textractResult.identifiedLines
                )

                return identifyTextResult
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
        return try await awsRekognition.detectModerationLabels(input: request)
    }

    private func detectLabels(
        image: Data
    ) async throws -> DetectLabelsOutputResponse {
        let image = RekognitionClientTypes.Image(bytes: image)
        let request = DetectLabelsInput(
            image: image
        )
        return try await awsRekognition.detectLabels(input: request)
    }

    private func detectAllLabels(image: Data) async throws -> Predictions.Identify.Labels.Result {
        do {
            async let labelsTask = try detectLabels(image: image)
            async let moderationLabelsTask = try detectModerationLabels(image: image)
            let (labelsOutput, moderationLabelsOutput) = try await (labelsTask, moderationLabelsTask)

            let labels = labelsOutput.labels ?? []
            let allLabels = IdentifyLabelsResultTransformers.processLabels(labels)
            let moderationLabels = moderationLabelsOutput.moderationLabels ?? []
            let unsafeContent = !moderationLabels.isEmpty
            return Predictions.Identify.Labels.Result(labels: allLabels, unsafeContent: unsafeContent)
        } catch let error as DetectLabelsOutputError {
            throw ServiceErrorMapping.detectLabels.map(error)
        } catch let error as DetectModerationLabelsOutputError {
            throw ServiceErrorMapping.detectModerationLabels.map(error)
        } catch {
            throw PredictionsError.unexpectedServiceErrorType(error)
        }
    }

    private func dataFromImage(url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw PredictionsError.client(.imageNotFound)
        }
    }
}
