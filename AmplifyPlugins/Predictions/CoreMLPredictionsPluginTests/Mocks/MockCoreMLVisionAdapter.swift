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

    func detectLabels(_ imageURL: URL) -> IdentifyLabelsResult? {
        return nil
    }

    func detectText(_ imageURL: URL) -> IdentifyTextResult? {
        return nil
    }

    func detectEntities(_ imageURL: URL) -> IdentifyEntitiesResult? {
        return nil
    }
}
