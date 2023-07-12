//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSPredictionsService: Resettable {
    func reset() async {
        awsTranslate = nil
        awsRekognition = nil
        awsTextract = nil
        awsComprehend = nil
        awsPolly = nil
        awsTranscribeStreaming = nil
        identifier = nil
    }
}
