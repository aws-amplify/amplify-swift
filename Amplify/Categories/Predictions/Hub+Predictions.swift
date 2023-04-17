//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension HubPayload.EventName.Predictions {
    static let identifyLabels = "Predictions.identifyLabels"
    static let identifyCelebrities = "Predictions.identifyCelebrities"
}

public extension HubPayload.EventName.Predictions {
    static let interpret = "Predictions.interpret"
}

public extension HubPayload.EventName.Predictions {
    static let speechToText = "Predictions.speechToText"
}

public extension HubPayload.EventName.Predictions {
    static let textToSpeech = "Predictions.textToSpeech"
}

public extension HubPayload.EventName.Predictions {
    static let translate = "Predictions.translate"
}
