//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition

class AWSRekognitionAdapter: AWSRekognitionBehavior {

    let awsRekognition: AWSRekognition

    init(_ awsRekognition: AWSRekognition) {
        self.awsRekognition = awsRekognition
    }

    func detectLabels(request: AWSRekognitionDetectLabelsRequest) -> AWSTask<AWSRekognitionDetectLabelsResponse> {
        return awsRekognition.detectLabels(request)
    }

    func getRekognition() -> AWSRekognition {
        return awsRekognition
    }

}
