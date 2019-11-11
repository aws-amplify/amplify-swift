//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition

extension AWSPredictionsService: AWSRekognitionServiceBehavior {

    func detectLabels(image: CGImage,
                      onEvent: @escaping AWSPredictionsService.RekognitionServiceEventHandler) {

        let request: AWSRekognitionDetectLabelsRequest = AWSRekognitionDetectLabelsRequest()
        let rekognitionImage = AWSRekognitionImage()

        let data = image.dataProvider?.data as Data?

        rekognitionImage?.bytes = data?.base64EncodedData(options: NSData.Base64EncodingOptions.endLineWithLineFeed)

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

            let newLabels = IdentifyLabelsResultUtils.process(labels)
            onEvent(.completed(IdentifyLabelsResult(labels: newLabels)))
            return nil
        }
    }
}
