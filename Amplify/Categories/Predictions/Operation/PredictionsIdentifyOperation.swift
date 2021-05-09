//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public protocol PredictionsIdentifyOperation: AmplifyOperation<
    PredictionsIdentifyRequest,
    IdentifyResult,
    PredictionsError
> { }

public extension HubPayload.EventName.Predictions {

    /// <#Description#>
    static let identifyLabels = "Predictions.identifyLabels"

    /// <#Description#>
    static let identifyCelebrities = "Predictions.identifyCelebrities"
}
