//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
import AWSTextract

extension AWSPredictionsService {
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

            let newLabels = IdentifyLabelsResultUtils.processLabels(labels)
            onEvent(.completed(IdentifyLabelsResult(labels: newLabels)))
            return nil
        }
    }

    func detectCelebs(image: URL, onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
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

            let newCelebs = IdentifyCelebsResultUtils.processCelebs(celebs)
            onEvent(.completed(IdentifyCelebsResult(celebrities: newCelebs)))
            return nil
        }
    }

    func detectEntities(image: URL, onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        if let collectionId = collectionId {
            //call detect face from collection if collection id passed in
            return detectFacesFromCollection(image: image, collectionId: collectionId, onEvent: onEvent)

        } else {
            //call detect faces
            return detectFaces(image: image, onEvent: onEvent)
        }
    }

    func detectText(image: URL,
                    format: FormatType,
                    onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {
        switch format {
        case .form:
            return analyzeDocument(image: image, features: ["FORMS"], onEvent: onEvent)
        case .table:
            return analyzeDocument(image: image, features: ["TABLES"], onEvent: onEvent)
        case .all:
        return analyzeDocument(image: image, features: ["FORMS", "TABLES"], onEvent: onEvent)
        case .plain:
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

                let identifyTextResult = IdentifyTextResultUtils.processText(rekognitionTextBlocks: rekognitionTextDetections)

                if identifyTextResult.words.count < 50 {
                    return onEvent(.completed(identifyTextResult))
                    //return nil
                } else {
                    self.detectDocumentText(image: image) { textractData in

                        guard let blocks = textractData.blocks else {
                           return  onEvent(.completed(identifyTextResult))
                           // return nil
                        }
                        if rekognitionTextDetections.count > blocks.count {
                       return onEvent(.completed(identifyTextResult))
                          // return nil
                        } else {

                            guard let textractResult = IdentifyTextResultUtils.processText(textractTextBlocks: blocks) else {
                               return onEvent(.failed(
                                    .networkError("No result was found.",
                                                  "Please make sure the image integrity is maintained before sending")))
                           // return nil
                            }
                           return onEvent(.completed(textractResult))
                           // return nil
                        }
                    }
                }

                return nil
            }

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

            let newFaces = IdentifyEntitiesResultUtils.processFaces(faces)
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
        request.maxFaces = maxFaces as NSNumber?

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

            let faceMatches = IdentifyEntitiesResultUtils.processCollectionFaces(faces)
            onEvent(.completed(IdentifyEntitiesFromCollectionResult(entities: faceMatches)))
            return nil
        }
    }
}
