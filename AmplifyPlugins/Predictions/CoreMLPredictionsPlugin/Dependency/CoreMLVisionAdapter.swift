//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Vision

class CoreMLVisionAdapter: CoreMLVisionBehavior {

    public func detectLabels(_ imageURL: URL) -> IdentifyLabelsResult? {
        var labelsResult = [Label]()
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        let request = VNClassifyImageRequest()
        try? handler.perform([request])

        guard let observations = request.results as? [VNClassificationObservation] else {
            return nil
        }

        let categories = observations.filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
        for category in categories {
            let metaData = LabelMetadata(confidence: Double(category.confidence * 100))
            let label = Label(name: category.identifier.capitalized, metadata: metaData)
            labelsResult.append(label)
        }
        return IdentifyLabelsResult(labels: labelsResult)
    }

    public func detectText(_ imageURL: URL) -> IdentifyTextResult? {
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try? handler.perform([request])

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return nil
        }

        var identifiedLines = [IdentifiedLine]()
        var rawLineText = [String]()
        for observation in observations {
            let detectedTextX = observation.boundingBox.origin.x
            let detectedTextY = observation.boundingBox.origin.y
            let detectedTextWidth = observation.boundingBox.width
            let detectedTextHeight = observation.boundingBox.height

            // Converting the y coordinate to iOS coordinate space and create a CGrect
            // out of it.
            let boundingbox = CGRect(x: detectedTextX,
                                     y: 1 - detectedTextHeight - detectedTextY,
                                     width: detectedTextWidth,
                                     height: detectedTextHeight)

            let topPredictions = observation.topCandidates(1)
            let prediction = topPredictions[0]
            let identifiedText = prediction.string
            let line = IdentifiedLine(text: identifiedText, boundingBox: boundingbox)
            identifiedLines.append(line)
            rawLineText.append(identifiedText)
        }
        return IdentifyTextResult(fullText: nil, words: nil, rawLineText: rawLineText, identifiedLines: identifiedLines)
    }

    func detectEntities(_ imageURL: URL) -> IdentifyEntitiesResult? {
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        try? handler.perform([faceLandmarksRequest])
        guard let observations = faceLandmarksRequest.results as? [VNFaceObservation] else {
            return nil
        }

        var entities: [Entity] = []
        for observation in observations {
            let pose = Pose(pitch: 0.0, // CoreML doesnot return pitch
                roll: observation.roll?.doubleValue ?? 0.0,
                yaw: observation.yaw?.doubleValue ?? 0.0)
            let entityMetaData = EntityMetadata(confidence: Double(observation.confidence),
                                                pose: pose)
            let entity = Entity(boundingBox: observation.boundingBox,
                                landmarks: mapLandmarks(observation.landmarks),
                                ageRange: nil,
                                attributes: nil,
                                gender: nil,
                                metadata: entityMetaData,
                                emotions: nil)
            entities.append(entity)
        }
        return IdentifyEntitiesResult(entities: entities)
    }

    // swiftlint:disable cyclomatic_complexity
    private func mapLandmarks(_ coreMLLandmarks: VNFaceLandmarks2D?) -> [Landmark] {
        var finalLandmarks: [Landmark] = []
        guard let landmarks = coreMLLandmarks else {
            return finalLandmarks
        }

        if let allPoints = landmarks.allPoints {
            finalLandmarks.append(Landmark(type: .allPoints,
                                            points: allPoints.normalizedPoints))
        }
        if let faceContour = landmarks.faceContour {
            finalLandmarks.append(Landmark(type: .faceContour,
                                            points: faceContour.normalizedPoints))
        }
        if let leftEye = landmarks.leftEye {
            finalLandmarks.append(Landmark(type: .leftEye,
                                            points: leftEye.normalizedPoints))
        }
        if let rightEye = landmarks.rightEye {
            finalLandmarks.append(Landmark(type: .rightEye,
                                            points: rightEye.normalizedPoints))
        }
        if let leftEyebrow = landmarks.leftEyebrow {
            finalLandmarks.append(Landmark(type: .leftEyebrow,
                                            points: leftEyebrow.normalizedPoints))
        }
        if let rightEyebrow = landmarks.rightEyebrow {
            finalLandmarks.append(Landmark(type: .rightEyebrow,
                                            points: rightEyebrow.normalizedPoints))
        }
        if let nose = landmarks.nose {
            finalLandmarks.append(Landmark(type: .nose,
                                            points: nose.normalizedPoints))
        }
        if let noseCrest = landmarks.noseCrest {
            finalLandmarks.append(Landmark(type: .noseCrest,
                                            points: noseCrest.normalizedPoints))
        }
        if let medianLine = landmarks.medianLine {
            finalLandmarks.append(Landmark(type: .medianLine,
                                            points: medianLine.normalizedPoints))
        }
        if let outerLips = landmarks.outerLips {
            finalLandmarks.append(Landmark(type: .outerLips,
                                            points: outerLips.normalizedPoints))
        }
        if let innerLips = landmarks.innerLips {
            finalLandmarks.append(Landmark(type: .innerLips,
                                            points: innerLips.normalizedPoints))
        }
        if let leftPupil = landmarks.leftPupil {
            finalLandmarks.append(Landmark(type: .leftPupil,
                                            points: leftPupil.normalizedPoints))
        }
        if let rightPupil = landmarks.rightPupil {
            finalLandmarks.append(Landmark(type: .rightPupil,
                                            points: rightPupil.normalizedPoints))
        }
        return finalLandmarks
    }

}
