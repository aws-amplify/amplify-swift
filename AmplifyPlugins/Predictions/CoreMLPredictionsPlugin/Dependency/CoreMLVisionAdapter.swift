//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Vision

struct CoreMLVisionAdapter: CoreMLVisionBehavior {

    public func detectLabels(_ imageURL: URL) -> [Label]? {
        var labelsResult = [Label]()
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        let request = VNClassifyImageRequest()
        try? handler.perform([request])

        guard let observations = request.results as? [VNClassificationObservation] else {
            return nil
        }

        let categories = observations.filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
        for category in categories {
            let metaData = LabelMetadata(confidence: Double(category.confidence))
            let label = Label(name: category.identifier, metadata: metaData)
            labelsResult.append(label)
        }
        return labelsResult
    }

    public func detectText(_ imageURL: URL) -> IdentifyTextResult? {
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        let request = VNRecognizeTextRequest()
        try? handler.perform([request])

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return nil
        }
        var fullText = ""
        var wordsList = [IdentifiedWord]()
        for observation in observations {
            let boundingbox = observation.boundingBox
            let topPredictions = observation.topCandidates(1)
            let prediction = topPredictions[0]
            let identifiedText = prediction.string
            let word = IdentifiedWord(text: identifiedText, boundingBox: boundingbox.toBoundingBox())
            wordsList.append(word)
            fullText += " \(identifiedText)"
        }
        return IdentifyTextResult(fullText: fullText, words: wordsList, rawLineText: nil, identifiedLines: nil)
    }
}

extension CGRect {

    func toBoundingBox() -> BoundingBox {
        let x = origin.x
        let y = origin.y
        let width = size.width
        let height = size.height
        let boundingBox = BoundingBox(left: Double(x),
                                      top: Double(y),
                                      width: Double(width),
                                      height: Double(height))
        return boundingBox
    }
}
