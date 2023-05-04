//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Vision

class CoreMLVisionAdapter: CoreMLVisionBehavior {

    func detectLabels(_ imageURL: URL) throws -> Predictions.Identify.Labels.Result? {
        var labelsResult = [Predictions.Label]()
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        let request = VNClassifyImageRequest()
#if targetEnvironment(simulator)
        request.usesCPUOnly = true
#endif
        try handler.perform([request])
        guard let observations = request.results else { return nil }

        let categories = observations.filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
        for category in categories {
            let metaData = Predictions.Label.Metadata(confidence: Double(category.confidence * 100))
            let label = Predictions.Label(name: category.identifier.capitalized, metadata: metaData)
            labelsResult.append(label)
        }
        return Predictions.Identify.Labels.Result(labels: labelsResult)
    }

    public func detectText(_ imageURL: URL) throws -> Predictions.Identify.Text.Result? {
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        let request = VNRecognizeTextRequest()
#if targetEnvironment(simulator)
        request.usesCPUOnly = true
#endif
        request.recognitionLevel = .accurate
        try handler.perform([request])
        guard let observations = request.results else { return nil }

        var identifiedLines = [Predictions.IdentifiedLine]()
        var rawLineText = [String]()
        for observation in observations {
            let detectedTextX = observation.boundingBox.origin.x
            let detectedTextY = observation.boundingBox.origin.y
            let detectedTextWidth = observation.boundingBox.width
            let detectedTextHeight = observation.boundingBox.height

            // Converting the y coordinate to iOS coordinate space and create a CGrect
            // out of it.
            let boundingbox = CGRect(
                x: detectedTextX,
                y: 1 - detectedTextHeight - detectedTextY,
                width: detectedTextWidth,
                height: detectedTextHeight
            )

            let topPredictions = observation.topCandidates(1)
            let prediction = topPredictions[0]
            let identifiedText = prediction.string
            let line = Predictions.IdentifiedLine(text: identifiedText, boundingBox: boundingbox)
            identifiedLines.append(line)
            rawLineText.append(identifiedText)
        }
        return Predictions.Identify.Text.Result(
            fullText: nil, words: nil, rawLineText: rawLineText, identifiedLines: identifiedLines
        )
    }

    func detectEntities(_ imageURL: URL) throws -> Predictions.Identify.Entities.Result? {
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
#if targetEnvironment(simulator)
        faceLandmarksRequest.usesCPUOnly = true
#endif
        try handler.perform([faceLandmarksRequest])
        guard let observations = faceLandmarksRequest.results else { return nil }

        var entities: [Predictions.Entity] = []
        for observation in observations {
            let pose = Predictions.Pose(pitch: 0.0, // CoreML doesnot return pitch
                            roll: observation.roll?.doubleValue ?? 0.0,
                            yaw: observation.yaw?.doubleValue ?? 0.0)
            let entityMetaData = Predictions.Entity.Metadata(confidence: Double(observation.confidence),
                                                pose: pose)
            let entity = Predictions.Entity(
                boundingBox: observation.boundingBox,
                landmarks: mapLandmarks(observation.landmarks),
                ageRange: nil,
                attributes: nil,
                gender: nil,
                metadata: entityMetaData,
                emotions: nil
            )
            entities.append(entity)
        }
        return Predictions.Identify.Entities.Result(entities: entities)
    }

    private func landmark(
        _ keyPath: KeyPath<VNFaceLandmarks2D, VNFaceLandmarkRegion2D?>,
        from landmarks: VNFaceLandmarks2D,
        type: Predictions.Landmark.Kind
    ) -> Predictions.Landmark? {
        if let value = landmarks[keyPath: keyPath] {
            return Predictions.Landmark(kind: type, points: value.normalizedPoints)
        }
        return nil
    }

    // swiftlint:disable cyclomatic_complexity
    private func mapLandmarks(_ coreMLLandmarks: VNFaceLandmarks2D?) -> [Predictions.Landmark] {
        guard let landmarks = coreMLLandmarks else { return [] }
        return [
            landmark(\.allPoints, from: landmarks, type: .allPoints),
            landmark(\.faceContour, from: landmarks, type: .faceContour),
            landmark(\.leftEye, from: landmarks, type: .leftEye),
            landmark(\.rightEye, from: landmarks, type: .rightEye),
            landmark(\.leftEyebrow, from: landmarks, type: .leftEyebrow),
            landmark(\.rightEyebrow, from: landmarks, type: .rightEyebrow),
            landmark(\.nose, from: landmarks, type: .nose),
            landmark(\.noseCrest, from: landmarks, type: .noseCrest),
            landmark(\.medianLine, from: landmarks, type: .medianLine),
            landmark(\.outerLips, from: landmarks, type: .outerLips),
            landmark(\.innerLips, from: landmarks, type: .innerLips),
            landmark(\.leftPupil, from: landmarks, type: .leftPupil),
            landmark(\.rightPupil, from: landmarks, type: .rightPupil)
        ]
            .compactMap { $0 }
    }
}
