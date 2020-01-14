//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranscribeStreaming

protocol AWSTranscribeStreamingServiceBehavior {

    typealias TranscribeServiceEventHandler = (TranscribeServiceEvent) -> Void
    typealias TranscribeServiceEvent = PredictionsEvent<ConvertResult, PredictionsError>

    func speechToText(audio: Data, onEvent: @escaping TranscribeServiceEventHandler)
}
