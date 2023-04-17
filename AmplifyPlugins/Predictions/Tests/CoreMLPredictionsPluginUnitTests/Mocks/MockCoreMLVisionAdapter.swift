//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import CoreMLPredictionsPlugin

class MockCoreMLVisionAdapter: CoreMLVisionBehavior {
    func detectLabels(_ imageURL: URL) -> Predictions.Identify.Labels.Result? {
        return nil
    }

    func detectText(_ imageURL: URL) -> Predictions.Identify.Text.Result? {
        return nil
    }

    func detectEntities(_ imageURL: URL) -> Predictions.Identify.Entities.Result? {
        return nil
    }
}
