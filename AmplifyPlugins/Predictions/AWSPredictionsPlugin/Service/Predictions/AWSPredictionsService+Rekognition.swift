//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
import AWSTextract

extension AWSPredictionsService: AWSRekognitionServiceBehavior {

    func detectLabels(image: URL,
                      onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {

        let request: AWSRekognitionDetectLabelsRequest = AWSRekognitionDetectLabelsRequest()
        let rekognitionImage: AWSRekognitionImage = AWSRekognitionImage()

        guard let imageData = try? Data(contentsOf: image) else {

            onEvent(.failed(
                .networkError("Something was wrong with the image file, make sure it exists.",
                              "Try choosing an image and sending it again.")))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage

        awsRekognition.detectLabels(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapRekognitionError(error)
                onEvent(.failed(
                    .networkError(predictionsErrorString.errorDescription,
                                  predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(
                    .unknownError("No result was found. An unknown error occurred",
                                  "Please try again.")))
                return nil
            }

            guard let labels = result.labels else {
                onEvent(.failed(
                    .networkError("No result was found.",
                                  "Please make sure the image integrity is maintained before sending")))
                return nil
            }

            let newLabels = IdentifyLabelsResultTransformers.processLabels(labels)
            onEvent(.completed(IdentifyLabelsResult(labels: newLabels)))
            return nil
        }
    }

    func detectCelebrities(image: URL, onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        let request: AWSRekognitionRecognizeCelebritiesRequest = AWSRekognitionRecognizeCelebritiesRequest()
        let rekognitionImage: AWSRekognitionImage = AWSRekognitionImage()

        guard let imageData = try? Data(contentsOf: image) else {

            onEvent(.failed(
                .networkError("Something was wrong with the image file, make sure it exists.",
                              "Try choosing an image and sending it again.")))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage

        awsRekognition.detectCelebs(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapRekognitionError(error)
                onEvent(.failed(
                    .networkError(predictionsErrorString.errorDescription,
                                  predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(
                    .unknownError("No result was found. An unknown error occurred",
                                  "Please try again.")))
                return nil
            }

            guard let celebs = result.celebrityFaces else {
                onEvent(.failed(
                    .networkError("No result was found.",
                                  "Please make sure the image integrity is maintained before sending")))
                return nil
            }

            let newCelebs = IdentifyCelebritiesResultTransformers.processCelebs(celebs)
            onEvent(.completed(IdentifyCelebritiesResult(celebrities: newCelebs)))
            return nil
        }
    }

    func detectEntities(image: URL, onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        if let collectionId = predictionsConfig.identifyConfig?.collectionId {
            //call detect face from collection if collection id passed in
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

            onEvent(.failed(
                .networkError("Something was wrong with the image file, make sure it exists.",
                              "Try choosing an image and sending it again.")))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage

        awsRekognition.detectFaces(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapRekognitionError(error)
                onEvent(.failed(
                    .networkError(predictionsErrorString.errorDescription,
                                  predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(
                    .unknownError("No result was found. An unknown error occurred",
                                  "Please try again.")))
                return nil
            }

            guard let faces = result.faceDetails else {
                onEvent(.failed(
                    .networkError("No result was found.",
                                  "Please make sure the image integrity is maintained before sending")))
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
            onEvent(.failed(
                .networkError("Something was wrong with the image file, make sure it exists.",
                              "Try choosing an image and sending it again.")))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage
        request.collectionId = collectionId
        request.maxFaces = predictionsConfig.identifyConfig?.maxEntities as NSNumber?

        awsRekognition.detectFacesFromCollection(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapRekognitionError(error)
                onEvent(.failed(
                    .networkError(predictionsErrorString.errorDescription,
                                  predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(
                    .unknownError("No result was found. An unknown error occurred",
                                  "Please try again.")))
                return nil
            }

            guard let faces = result.faceMatches else {
                onEvent(.failed(
                    .networkError("No result was found.",
                                  "Please make sure the image integrity is maintained before sending")))
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

            onEvent(.failed(
                .networkError("Something was wrong with the image file, make sure it exists.",
                              "Try choosing an image and sending it again.")))
            return
        }

        rekognitionImage.bytes = imageData
        request.image = rekognitionImage

        awsRekognition.detectText(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapRekognitionError(error)
                onEvent(.failed(
                    .networkError(predictionsErrorString.errorDescription,
                                  predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(
                    .unknownError("No result was found. An unknown error occurred",
                                  "Please try again.")))
                return nil
            }

            guard let rekognitionTextDetections = result.textDetections else {
                onEvent(.failed(
                    .networkError("No result was found.",
                                  "Please make sure the image integrity is maintained before sending")))
                return nil
            }

            let identifyTextResult = IdentifyTextResultTransformers.processText(
                rekognitionTextBlocks: rekognitionTextDetections)

            //if limit of words is under 50 return rekognition response
            //otherwise call textract because their limit is higher
            if let words = identifyTextResult.words, words.count < self.rekognitionWordLimit {
                onEvent(.completed(identifyTextResult))
                return nil
            } else {
                self.detectDocumentText(image: imageData, onEvent: onEvent).continueWith { task in

                    guard task.error == nil else {
                        let error = task.error! as NSError
                        let predictionsErrorString = PredictionsErrorHelper.mapRekognitionError(error)
                        onEvent(.failed(
                            .networkError(predictionsErrorString.errorDescription,
                                          predictionsErrorString.recoverySuggestion)))
                        return nil
                    }

                    guard let result = task.result else {
                        onEvent(.failed(
                            .unknownError("No result was found. An unknown error occurred",
                                          "Please try again.")))
                        return nil
                    }

                    guard let textractTextDetections = result.blocks else {
                        onEvent(.failed(
                            .networkError("No result was found.",
                                          "Please make sure the image integrity is maintained before sending")))
                        return nil
                    }

                    if rekognitionTextDetections.count > textractTextDetections.count {
                        onEvent(.completed(identifyTextResult))
                    } else {
                        let textractResult = IdentifyTextResultTransformers.processText(
                            textractTextBlocks: textractTextDetections)
                        onEvent(.completed(textractResult))
                        return nil

                    }
                    return nil
                }

            }
            return nil
        }
    }

}
