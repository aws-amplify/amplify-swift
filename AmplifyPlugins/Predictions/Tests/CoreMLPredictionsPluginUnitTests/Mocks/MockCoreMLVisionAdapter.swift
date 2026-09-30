//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import CoreMLPredictionsPlugin

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven
// by a single test at a time.
final class MockCoreMLVisionAdapter: CoreMLVisionBehavior, @unchecked Sendable {
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
