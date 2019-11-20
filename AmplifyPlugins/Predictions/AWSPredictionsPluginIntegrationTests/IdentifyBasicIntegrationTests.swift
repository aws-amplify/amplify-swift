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

class IdentifyBasicIntegrationTests: AWSPredictionsPluginTestBase {

    /// Given: An Image
    /// When: Image is sent to Rekognition
    /// Then: The operation completes successfully
    func testIdentifyLabels() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.labels),
                                                     image: url,
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

    func testIdentifyModerationLabels() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.moderation),
                                                     image: url,
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

    func testIdentifyAllLabels() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.all),
                                                     image: url,
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

    func testIdentifyCelebrities() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageCeleb", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectCelebrity,
                                                     image: url,
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

    func testIdentifyEntities() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectEntities,
                                                     image: url,
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

    func testIdentifyTextPlain() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.plain),
                                                     image: url,
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

    func testIdentifyTextAll() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.all),
                                                     image: url,
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

    func testIdentifyTextForms() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.form),
                                                     image: url,
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

    func testIdentifyTextTables() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.table),
                                                     image: url,
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
