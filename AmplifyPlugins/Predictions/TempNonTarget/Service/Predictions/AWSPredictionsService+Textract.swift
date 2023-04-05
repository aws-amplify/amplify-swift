//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract
import Amplify

public typealias DetectDocumentTextCompletedHandler = AWSTask<AWSTextractDetectDocumentTextResponse>

extension AWSPredictionsService: AWSTextractServiceBehavior {
    func detectDocumentText(image: Data,
                            onEvent: @escaping TextractServiceEventHandler) -> DetectDocumentTextCompletedHandler {
        let request: AWSTextractDetectDocumentTextRequest = AWSTextractDetectDocumentTextRequest()
        let document: AWSTextractDocument = AWSTextractDocument()

        document.bytes = image
        request.document = document

       return awsTextract.detectDocumentText(request: request)

    }

    func analyzeDocument(
        image: URL,
        features: [String],
        onEvent: @escaping AWSPredictionsService.TextractServiceEventHandler) {
        let request: AWSTextractAnalyzeDocumentRequest = AWSTextractAnalyzeDocumentRequest()
        let document: AWSTextractDocument = AWSTextractDocument()

        guard let imageData = try? Data(contentsOf: image) else {

            onEvent(.failed(
                .network("Something was wrong with the image file, make sure it exists.",
                              "Try choosing an image and sending it again.")))
            return
        }
        document.bytes = imageData
        request.document = document
        request.featureTypes = features

        awsTextract.analyzeDocument(request: request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                onEvent(.failed(
                    .network(predictionsErrorString.errorDescription,
                                  predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(
                    .unknown("No result was found. An unknown error occurred",
                                  "Please try again.")))
                return nil
            }

            guard let blocks = result.blocks else {
                onEvent(.failed(
                    .network("No result was found.",
                                  "Please make sure the image integrity is maintained before sending")))
                return nil
            }

            let textResult = IdentifyTextResultTransformers.processText(blocks)
            onEvent(.completed(textResult))
            return nil
        }
    }
}
