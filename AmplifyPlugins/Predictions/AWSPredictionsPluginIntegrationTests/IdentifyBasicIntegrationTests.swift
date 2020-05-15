//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import AWSMobileClient
@testable import Amplify
import AWSPredictionsPlugin
import AWSRekognition
import XCTest

// swiftlint:disable:next type_body_length
class IdentifyBasicIntegrationTests: XCTestCase {

     let region: JSONValue = "us-west-2"
     let networkTimeout = TimeInterval(180) // 180 seconds to wait before network timeouts

    override func setUp() {
        setupMobileClient()
    }

    override func tearDown() {
        print("Amplify reset")
        Amplify.reset()
        sleep(5)
    }

    private func setupAmplify(withCollection: Bool = false) {
        // Set up Amplify predictions configuration
        var predictionsConfig = PredictionsCategoryConfiguration(
            plugins: [
                "awsPredictionsPlugin": [
                    "defaultRegion": region
                ]
            ]
        )
        if withCollection {
         predictionsConfig = PredictionsCategoryConfiguration(
            plugins: [
                "awsPredictionsPlugin": [
                    "defaultRegion": region,
                    "identify": [
                        "identifyEntities": [
                            "collectionId": "TestCollection",
                            "celebrityDetectionEnabled": "true",
                            "maxFaces": 50,
                            "region": region,
                            "defaultNetworkPolicy": "auto"
                        ]
                    ]
                ]
            ]
        )
        }

        let amplifyConfig = AmplifyConfiguration(predictions: predictionsConfig)

        // Set up Amplify
        let predictionsPlugin = AWSPredictionsPlugin()
        do {
            try Amplify.add(plugin: predictionsPlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }
        print("Amplify initialized")
    }

    private func setupMobileClient() {
        // Set up AWSMobileClient
        let testBundle = Bundle(for: type(of: self))
        guard let configurationFile = testBundle.url(forResource: "awsconfiguration", withExtension: "json") else {
            XCTFail("Could not find the configuration file. Please check awsconfiguration.json file is in the path.")
            return
        }
        guard let configurationData = try? Data(contentsOf: configurationFile) else {
            XCTFail("Could not read configuration data.")
            return
        }
        guard let configurationJson = try? JSONSerialization.jsonObject(with: configurationData)
            as? [String: Any] else {

            XCTFail("Could not parse the configuration data.")
            return
        }
        AWSInfo.configureDefaultAWSInfo(configurationJson)

        let mobileClientIsInitialized = expectation(description: "AWSMobileClient is initialized")
        AWSMobileClient.default().initialize { userState, error in
            guard error == nil else {
                XCTFail("Error initializing AWSMobileClient. Error: \(error!.localizedDescription)")
                return
            }
            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }
            if userState != UserState.signedOut {
                AWSMobileClient.default().signOut()
            }
            mobileClientIsInitialized.fulfill()
        }
        wait(for: [mobileClientIsInitialized], timeout: networkTimeout)
        print("AWSMobileClient Initialized")
    }

    /// Given: An Image
    /// When: Image is sent to Rekognition
    /// Then: The operation completes successfully
    func testIdentifyLabels() {
        setupAmplify()
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.labels),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyModerationLabels() {
         setupAmplify()
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.moderation),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyAllLabels() {
         setupAmplify()
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.all),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyCelebrities() {
         setupAmplify()
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageCeleb", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectCelebrity,
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyEntityMatches() {
        setupAmplify(withCollection: true)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectEntities,
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyEntities() {
        setupAmplify(withCollection: false)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectEntities,
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyTextPlain() {
         setupAmplify()
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.plain),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyTextAll() {
         setupAmplify()
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.all),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyTextForms() {
         setupAmplify()
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.form),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyTextTables() {
         setupAmplify()
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.table),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
                                                        switch event {
                                                        case .success:
                                                            completeInvoked.fulfill()
                                                        case .failure(let error):
                                                            XCTFail("Failed with \(error)")
                                                        }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

}
