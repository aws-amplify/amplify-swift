//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract

extension AWSPredictionsService {
    func detectDocumentText(image: URL, onEvent: @escaping (AWSTextractDetectDocumentTextResponse) -> Void) {

    }

    func analyzeDocument(
        image: URL,
        features: [String],
        onEvent: @escaping AWSPredictionsService.TextractServiceEventHandler) {
        let request: AWSTextractAnalyzeDocumentRequest = AWSTextractAnalyzeDocumentRequest()
        let document: AWSTextractDocument = AWSTextractDocument()

        guard let imageData = try? Data(contentsOf: image) else {

            onEvent(.failed(
                .networkError("Something was wrong with the image file, make sure it exists.",
                              "Try choosing an image and sending it again.")))
            return
        }
        document.bytes = imageData
        request.document = document
        request.featureTypes = features


    }
}
