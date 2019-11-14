//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import AWSMobileClient
import Amplify
import AWSPredictionsPlugin
import AWSRekognition
import XCTest

class AWSPredictionsPluginIdentifyIntegrationTest: AWSPredictionsPluginTestBase {

    /// Given: An Image
    /// When: Image is sent to Rekognition
    /// Then: The operation completes successfully
    func testIdentifyLabels() {

        guard let image = UIImage(named: "testImage") else { return }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels,
                                                     image: image,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

}
