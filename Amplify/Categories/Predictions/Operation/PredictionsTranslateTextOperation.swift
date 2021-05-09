//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public protocol PredictionsTranslateTextOperation: AmplifyOperation<PredictionsTranslateTextRequest,
TranslateTextResult, PredictionsError> { }

public extension HubPayload.EventName.Predictions {

    /// <#Description#>
    static let translate = "Predictions.translate"
}
