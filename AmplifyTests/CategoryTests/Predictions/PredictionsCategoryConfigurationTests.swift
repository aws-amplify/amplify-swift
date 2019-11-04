//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import CwlPreconditionTesting

@testable import AmplifyTestCommon
@testable import Amplify

class PredictionsCategoryConfigurationTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
    }

    func testCanAddPlugin() throws {
        let plugin = MockPredictionsCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigurePlugin() throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Predictions)
        XCTAssertNotNil(try Amplify.Predictions.getPlugin(for: "MockPredictionsCategoryPlugin"))
    }

    func testCanResetPlugin() throws {
        let plugin = MockPredictionsCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.Predictions.getPlugin(for: "MockPredictionsCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case PluginError.noSuchPlugin = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testCanRegisterMultiplePlugins() throws {
        let plugin1 = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let config = PredictionsCategoryConfiguration(
            plugins: [
                "MockPredictionsCategoryPlugin": true,
                "MockSecondPredictionsCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Predictions.getPlugin(for: "MockPredictionsCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Predictions.getPlugin(for: "MockSecondPredictionsCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockPredictionsCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "textToTranslate" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let config = PredictionsCategoryConfiguration(plugins: ["MockPredictionsCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)

        _ = Amplify.Predictions.convert(textToTranslate: "Sample",
                                        language: nil,
                                        targetLanguage: nil,
                                        listener: nil,
                                        options: nil)
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockPredictionsCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "textToTranslate" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondPredictionsCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "textToTranslate" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let config = PredictionsCategoryConfiguration(
            plugins: [
                "MockPredictionsCategoryPlugin": true,
                "MockSecondPredictionsCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)
        _ = try Amplify.Predictions.getPlugin(for: "MockSecondPredictionsCategoryPlugin")
            .convert(textToTranslate: "Sample",
                     language: nil,
                     targetLanguage: nil,
                     listener: nil,
                     options: nil)
        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingWithMultiplePlugins() throws {
        let plugin1 = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let config = PredictionsCategoryConfiguration(
            plugins: [
                "MockPredictionsCategoryPlugin": true,
                "MockSecondPredictionsCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)

        let exception: BadInstructionException? = catchBadInstruction {
            _ = Amplify.Predictions.convert(textToTranslate: "Sample",
                                            language: nil,
                                            targetLanguage: nil,
                                            listener: nil,
                                            options: nil)
        }
        XCTAssertNotNil(exception)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockPredictionsCategoryPlugin()
        let configureShouldBeInvokedFromCategory =
            expectation(description: "Configure should be invoked by Amplify.configure()")
        let configureShouldBeInvokedDirectly =
            expectation(description: "Configure should be invoked by getPlugin().configure()")

        var invocationCount = 0
        plugin.listeners.append { message in
            if message == "configure(using:)" {
                invocationCount += 1
                switch invocationCount {
                case 1: configureShouldBeInvokedFromCategory.fulfill()
                case 2: configureShouldBeInvokedDirectly.fulfill()
                default: XCTFail("Expected configure() to be called only two times, but got \(invocationCount)")
                }
            }
        }
        try Amplify.add(plugin: plugin)

        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)
        try Amplify.Predictions.getPlugin(for: "MockPredictionsCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        let exception: BadInstructionException? = catchBadInstruction {
            _ = Amplify.Predictions.convert(textToTranslate: "Sample",
                                            language: nil,
                                            targetLanguage: nil,
                                            listener: nil,
                                            options: nil)
        }
        XCTAssertNotNil(exception)
    }

    // MARK: - Test internal config behavior guarantees

    func testThrowsConfiguringTwice() throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        try Amplify.Predictions.configure(using: config)
        XCTAssertThrowsError(try Amplify.Predictions.configure(using: config),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }
    }

    func testCanConfigureAfterReset() throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        try Amplify.Predictions.configure(using: config)

        let semaphore = DispatchSemaphore(value: 1)
        Amplify.Predictions.reset { semaphore.signal() }
        semaphore.wait()

        XCTAssertNoThrow(try Amplify.Predictions.configure(using: config))
    }

}
