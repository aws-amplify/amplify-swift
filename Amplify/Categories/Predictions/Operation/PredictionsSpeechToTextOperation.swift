//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public protocol PredictionsSpeechToTextOperation: AmplifyOperation<PredictionsSpeechToTextRequest,
SpeechToTextResult, PredictionsError> { }

public extension HubPayload.EventName.Predictions {

    /// <#Description#>
    static let speechToText = "Predictions.speechToText"
}
