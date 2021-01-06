//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition

protocol AWSRekognitionServiceBehavior {

    typealias RekognitionServiceEventHandler = (RekognitionServiceEvent) -> Void
    typealias RekognitionServiceEvent = PredictionsEvent<IdentifyResult, PredictionsError>

    func detectLabels(image: URL,
                      type: LabelType,
                      onEvent: @escaping RekognitionServiceEventHandler)

    func detectCelebrities(image: URL, onEvent: @escaping RekognitionServiceEventHandler)

    func detectText(image: URL, format: TextFormatType, onEvent: @escaping RekognitionServiceEventHandler)

    func detectEntities(image: URL, onEvent: @escaping RekognitionServiceEventHandler)
}
