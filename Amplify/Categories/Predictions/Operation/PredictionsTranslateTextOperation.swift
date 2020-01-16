//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol PredictionsTranslateTextOperation: AmplifyOperation<PredictionsTranslateTextRequest,
Void, TranslateTextResult, PredictionsError> { }

public extension HubPayload.EventName.Predictions {
    static let translate = "Predictions.translate"
}
