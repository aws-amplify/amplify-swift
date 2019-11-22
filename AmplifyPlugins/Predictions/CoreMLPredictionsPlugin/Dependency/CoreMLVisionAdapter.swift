//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
            let boundingbox = observation.boundingBox
            let topPredictions = observation.topCandidates(1)
            let prediction = topPredictions[0]
            let identifiedText = prediction.string
            let line = IdentifiedLine(text: identifiedText, boundingBox: boundingbox)
            identifiedLines.append(line)
            rawLineText.append(identifiedText)
        }
        return IdentifyTextResult(fullText: nil, words: nil, rawLineText: rawLineText, identifiedLines: identifiedLines)
    }
}
