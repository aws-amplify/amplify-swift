//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public protocol PredictionsTextToSpeechOperation: AmplifyOperation<
    PredictionsTextToSpeechRequest,
    TextToSpeechResult,
    PredictionsError
> { }

public extension HubPayload.EventName.Predictions {

    /// <#Description#>
    static let textToSpeech = "Predictions.textToSpeech"
}
