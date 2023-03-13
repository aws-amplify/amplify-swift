//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
import AWSTextract

typealias DetectModerationLabelsCompletedHandler = AWSTask<AWSRekognitionDetectModerationLabelsResponse>

typealias DetectLabelsCompletedHandler = AWSTask<AWSRekognitionDetectLabelsResponse>

// swiftlint:disable file_length
extension AWSPredictionsService: AWSRekognitionServiceBehavior {

    func detectLabels(image: URL,
                      type: LabelType,
                      onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        guard let imageData = try? Data(contentsOf: image) else {

            onEvent(.failed(.network(AWSRekognitionErrorMessage.imageNotFound.errorDescription,
                                     AWSRekognitionErrorMessage.imageNotFound.recoverySuggestion)))
                   return
        }

        switch type {
        case .labels:
            detectRekognitionLabels(image: imageData, onEvent: onEvent).continueWith { (task) -> Any? in
                guard task.error == nil else {
                    let error = task.error! as NSError
                    let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                    onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                             predictionsErrorString.recoverySuggestion)))
                    return nil
                }

                guard let result = task.result else {
                    onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                             AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                    return nil
                }

                guard let labels = result.labels else {
                    onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                             AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                    return nil
                }

                let newLabels = IdentifyLabelsResultTransformers.processLabels(labels)
                onEvent(.completed(IdentifyLabelsResult(labels: newLabels, unsafeContent: nil)))
                return nil
            }
        case .moderation:
            detectModerationLabels(image: imageData, onEvent: onEvent).continueWith { (task) -> Any? in
                guard task.error == nil else {
                    let error = task.error! as NSError
                    let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                    onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                             predictionsErrorString.recoverySuggestion)))
                    return nil
                }

                guard let result = task.result else {
                    onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                              AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                    return nil
                }

                guard let moderationRekognitionlabels = result.moderationLabels else {
                    onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                             AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                    return nil
                }

                let unsafeContent: Bool = !moderationRekognitionlabels.isEmpty

                let labels = IdentifyLabelsResultTransformers.processModerationLabels(moderationRekognitionlabels)
                onEvent(.completed(IdentifyLabelsResult(labels: labels, unsafeContent: unsafeContent)))
                return nil
            }
        case .all:
            return detectAllLabels(image: imageData, onEvent: onEvent)
        }
    }

    func detectCelebrities(image: URL, onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        let request: AWSRekognitionRecognizeCelebritiesRequest = AWSRekognitionRecognizeCelebritiesRequest()
        let rekognitionImage: AWSRekognitionImage = AWSRekognitionImage()

        guard let imageData = try? Data(contentsOf: image) else {
            onEvent(.failed(.network(AWSRekognitionErrorMessage.imageNotFound.errorDescription,
                                     AWSRekognitionErrorMessage.imageNotFound.recoverySuggestion)))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage

        awsRekognition.detectCelebs(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                         predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                return nil
            }

            guard let celebs = result.celebrityFaces else {
                onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                return nil
            }

            let newCelebs = IdentifyCelebritiesResultTransformers.processCelebs(celebs)
            onEvent(.completed(IdentifyCelebritiesResult(celebrities: newCelebs)))
            return nil
        }
    }

    func detectEntities(image: URL, onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        if let collectionId = predictionsConfig.identify.identifyEntities?.collectionId {
            // call detect face from collection if collection id passed in
            return detectFacesFromCollection(image: image, collectionId: collectionId, onEvent: onEvent)

        }
        return detectFaces(image: image, onEvent: onEvent)
    }

    func detectText(image: URL,
                    format: TextFormatType,
                    onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        switch format {
        case .form, .all, .table:
            return analyzeDocument(image: image, features: format.textractServiceFormatType, onEvent: onEvent)
        case .plain:
            return detectTextRekognition(image: image, onEvent: onEvent)
        }
    }

    private func detectFaces(image: URL, onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        let request: AWSRekognitionDetectFacesRequest = AWSRekognitionDetectFacesRequest()
        let rekognitionImage: AWSRekognitionImage = AWSRekognitionImage()

        guard let imageData = try? Data(contentsOf: image) else {
            onEvent(.failed(.network(AWSRekognitionErrorMessage.imageNotFound.errorDescription,
                                     AWSRekognitionErrorMessage.imageNotFound.recoverySuggestion)))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage

        awsRekognition.detectFaces(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                         predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                return nil
            }

            guard let faces = result.faceDetails else {
                onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                return nil
            }

            let newFaces = IdentifyEntitiesResultTransformers.processFaces(faces)
            onEvent(.completed(IdentifyEntitiesResult(entities: newFaces)))
            return nil
        }
    }

    private func detectFacesFromCollection(image: URL,
                                           collectionId: String,
                                           onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        let request: AWSRekognitionSearchFacesByImageRequest = AWSRekognitionSearchFacesByImageRequest()
        let rekognitionImage: AWSRekognitionImage = AWSRekognitionImage()

        guard let imageData = try? Data(contentsOf: image) else {
            onEvent(.failed(.network(AWSRekognitionErrorMessage.imageNotFound.errorDescription,
                                     AWSRekognitionErrorMessage.imageNotFound.recoverySuggestion)))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage
        request.collectionId = collectionId
        let maxEntities = Int(predictionsConfig.identify.identifyEntities?.maxEntities ?? "50") ?? 50
        request.maxFaces = NSNumber(value: maxEntities)

        awsRekognition.detectFacesFromCollection(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                         predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                return nil
            }

            guard let faces = result.faceMatches else {
                onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                return nil
            }

            let faceMatches = IdentifyEntitiesResultTransformers.processCollectionFaces(faces)
            onEvent(.completed(IdentifyEntityMatchesResult(entities: faceMatches)))
            return nil
        }
    }

    private func detectTextRekognition(
        image: URL,
        onEvent: @escaping RekognitionServiceEventHandler) {
        let request: AWSRekognitionDetectTextRequest = AWSRekognitionDetectTextRequest()
        let rekognitionImage: AWSRekognitionImage = AWSRekognitionImage()

        guard let imageData = try? Data(contentsOf: image) else {
            onEvent(.failed(.network(AWSRekognitionErrorMessage.imageNotFound.errorDescription,
                                     AWSRekognitionErrorMessage.imageNotFound.recoverySuggestion)))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage

        awsRekognition.detectText(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                         predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                return nil
            }

            guard let rekognitionTextDetections = result.textDetections else {
                onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                return nil
            }
            let identifyTextResult = IdentifyTextResultTransformers.processText(rekognitionTextDetections)

            // if limit of words is under 50 return rekognition response
            // otherwise call textract because their limit is higher
            if let words = identifyTextResult.words, words.count < self.rekognitionWordLimit {
                onEvent(.completed(identifyTextResult))
                return nil
            } else {
                self.detectDocumentText(image: imageData, onEvent: onEvent).continueWith { task in

                    guard task.error == nil else {
                        let error = task.error! as NSError
                        let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                        onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                                 predictionsErrorString.recoverySuggestion)))
                        return nil
                    }

                    guard let result = task.result else {
                        onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                                 AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                        return nil
                    }

                    guard let textractTextDetections = result.blocks else {
                        onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                                 AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                        return nil
                    }

                    if rekognitionTextDetections.count > textractTextDetections.count {
                        onEvent(.completed(identifyTextResult))
                    } else {
                        let textractResult = IdentifyTextResultTransformers.processText(textractTextDetections)
                        onEvent(.completed(textractResult))
                        return nil
                    }
                    return nil
                }
            }
            return nil
        }
    }

    private func detectModerationLabels(image: Data, onEvent: @escaping
        RekognitionServiceEventHandler) -> DetectModerationLabelsCompletedHandler {
        let request: AWSRekognitionDetectModerationLabelsRequest = AWSRekognitionDetectModerationLabelsRequest()
        let rekognitionImage: AWSRekognitionImage = AWSRekognitionImage()
        rekognitionImage.bytes = image
        request.image = rekognitionImage
        return awsRekognition.detectModerationLabels(request: request)
    }

    private func detectRekognitionLabels(image: Data, onEvent: @escaping
        RekognitionServiceEventHandler) -> DetectLabelsCompletedHandler {
        let request: AWSRekognitionDetectLabelsRequest = AWSRekognitionDetectLabelsRequest()
        let rekognitionImage: AWSRekognitionImage = AWSRekognitionImage()
        rekognitionImage.bytes = image
        request.image = rekognitionImage
        return awsRekognition.detectLabels(request: request)
    }

    private func detectAllLabels(image: Data, onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        let dispatchGroup = DispatchGroup()
        var allLabels = [Label]()
        var unsafeContent: Bool = false
        var errorOcurred: Bool = false

        dispatchGroup.enter()
        detectRekognitionLabels(image: image, onEvent: onEvent).continueWith { (task) -> Any? in
            defer {
                dispatchGroup.leave()
            }

            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                         predictionsErrorString.recoverySuggestion)))
                errorOcurred = true
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                errorOcurred = true
                return nil
            }

            guard let labels = result.labels else {
                onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                errorOcurred = true
                return nil
            }

            allLabels = IdentifyLabelsResultTransformers.processLabels(labels)
            return nil
        }

        dispatchGroup.wait()

        // No need to execute `detectModerationLabels()` if error occurs on `detectRekognitionLabels()`
        guard !errorOcurred else {
            return
        }

        dispatchGroup.enter()
        detectModerationLabels(image: image, onEvent: onEvent).continueWith {(task) -> Any? in
            defer {
                dispatchGroup.leave()
            }

            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                onEvent(.failed(.network(predictionsErrorString.errorDescription,
                                         predictionsErrorString.recoverySuggestion)))
                errorOcurred = true
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknown(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                errorOcurred = true
                return nil
            }

            guard let moderationRekognitionLabels = result.moderationLabels else {
                onEvent(.failed(.network(AWSRekognitionErrorMessage.noResultFound.errorDescription,
                                         AWSRekognitionErrorMessage.noResultFound.recoverySuggestion)))
                errorOcurred = true
                return nil
            }

            unsafeContent = !moderationRekognitionLabels.isEmpty
            return nil
        }
        dispatchGroup.wait()

        if !errorOcurred {
            onEvent(.completed(IdentifyLabelsResult(labels: allLabels, unsafeContent: unsafeContent)))
        }
    }
}
