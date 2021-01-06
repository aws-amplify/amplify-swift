//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol PredictionsTextToSpeechOperation: AmplifyOperation<
    PredictionsTextToSpeechRequest,
    TextToSpeechResult,
    PredictionsError
> { }

public extension HubPayload.EventName.Predictions {
    static let textToSpeech = "Predictions.textToSpeech"
}
