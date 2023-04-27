//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class PredictionsCategoryConfigurationTests: XCTestCase {

    override func setUp() async throws {
        await Amplify.reset()
    }

    /// Test if we can add a new prediction plugin
    ///
    /// - Given: UnConfigured Amplify framework
    /// - When:
    ///    - I add a new Prediction plugin to Amplify
    /// - Then:
    ///    - Plugin should be added  without throwing any error
    ///
    func testCanAddPlugin() throws {
        let plugin = MockPredictionsCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    /// Test if Prediction plugin can be configured
    ///
    /// - Given: UnConfigured Amplify framework
    /// - When:
    ///    - I add a new Prediction plugin and add configuration for the plugin
    /// - Then:
    ///    - Prediction plugin should be configured correctly
    ///
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

    /// Test if resetting Prediction category works
    ///
    /// - Given: Amplify framework configured with Prediction plugin
    /// - When:
    ///    - I call await Amplify.reset()
    /// - Then:
    ///    - The plugin should invoke the reset method.
    ///
    func testCanResetPlugin() async throws {
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
        await Amplify.reset()
        await waitForExpectations(timeout: 1.0)
    }

    /// Test whether calling reset removes the plugin added
    ///
    /// - Given: Amplify framework configured with Prediction plugin
    /// - When:
    ///    - I call Amplify.reset
    /// - Then:
    ///    - Predicitons plugin should no longer work
    ///
    func testResetRemovesAddedPlugin() async throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        XCTAssertThrowsError(
            try Amplify.Predictions.getPlugin(for: "MockPredictionsCategoryPlugin"),
            "Getting a plugin after reset() should throw"
        ) { error in
                guard case PredictionsError.client = error else {
                    XCTFail("Expected PluginError.noSuchPlugin")
                    return
                }
            }
    }

    /// Test if we can register multiple plugins
    ///
    /// - Given: UnConfigured Amplify framework
    /// - When:
    ///    - I configure Amplify with multiple plugins for Predictions
    /// - Then:
    ///    - I should be able to access individual plugins I added.
    ///
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

    /// Test if the default plugin works
    ///
    /// - Given: Amplify configured with Prediction plugin
    /// - When:
    ///    - I invoke a API from prediction with default invocation
    /// - Then:
    ///    - API should complete without error
    ///
    func testCanUseDefaultPluginIfOnlyOnePlugin() async throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let config = PredictionsCategoryConfiguration(plugins: ["MockPredictionsCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(predictions: config)
        try Amplify.configure(amplifyConfig)
        _ = try await Amplify.Predictions.convert(.translateText("Sample", from: nil, to: nil))
    }

    /// Test if I can pick a specific plugin
    ///
    /// - Given: Amplify configured with multiple Prediction plugins
    /// - When:
    ///    - I coose one plugin and call one of the Prediction API
    /// - Then:
    ///    - API should complete without error for one plugin
    ///
//    func testCanUseSpecifiedPlugin() throws {
//        let plugin1 = MockPredictionsCategoryPlugin()
//        let methodShouldNotBeInvokedOnDefaultPlugin =
//        expectation(description: "test method should not be invoked on default plugin")
//        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
//        plugin1.listeners.append { message in
//            if message == "textToTranslate" {
//                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
//            }
//        }
//        try Amplify.add(plugin: plugin1)
//
//        let plugin2 = MockSecondPredictionsCategoryPlugin()
//        let methodShouldBeInvokedOnSecondPlugin =
//        expectation(description: "test method should be invoked on second plugin")
//        plugin2.listeners.append { message in
//            if message == "textToTranslate" {
//                methodShouldBeInvokedOnSecondPlugin.fulfill()
//            }
//        }
//        try Amplify.add(plugin: plugin2)
//
//        let config = PredictionsCategoryConfiguration(
//            plugins: [
//                "MockPredictionsCategoryPlugin": true,
//                "MockSecondPredictionsCategoryPlugin": true
//            ]
//        )
//
//        let amplifyConfig = AmplifyConfiguration(predictions: config)
//
//        try Amplify.configure(amplifyConfig)
//        _ = try Amplify.Predictions.getPlugin(for: "MockSecondPredictionsCategoryPlugin")
//            .convert(textToTranslate: "Sample",
//                     language: nil,
//                     targetLanguage: nil,
//                     options: nil,
//                     listener: nil)
//        waitForExpectations(timeout: 1.0)
//    }

    /// Test if we get error when trying default plugin when multiple plugin added.
    ///
    /// - Given: Amplify configured with multiple prediction plugin
    /// - When:
    ///    - I try to invoke an API with default plugin
    /// - Then:
    ///    - Should throw an exception
    ///
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

//        try XCTAssertThrowFatalError {
//            _ = Amplify.Predictions.convert(textToTranslate: "Sample",
//                                            language: nil,
//                                            targetLanguage: nil,
//                                            options: nil,
//                                            listener: nil)
//        }
    }

    /// Test if configuration Prediction plugin directly works
    ///
    /// - Given: Amplify with Prediction plugin configured
    /// - When:
    ///    - I try to add a new configuration to the same plugin
    /// - Then:
    ///    - Should work without any error.
    ///
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

    // MARK: - Test internal config behavior guarantees

    /// Test if configuring twice throws an exception
    ///
    /// - Given: Amplify with Prediction plugin configured
    /// - When:
    ///    - I try to configure Prediction again
    /// - Then:
    ///    - Should throw an exception
    ///
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

    /// Test if configuring after reset works
    ///
    /// - Given: Amplify framework with Predictons configured
    /// - When:
    ///    - I reset Amplify and then configure again
    /// - Then:
    ///    - Should not throw any error
    ///
    func testCanConfigureAfterReset() async throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        try Amplify.Predictions.configure(using: config)

        await Amplify.Predictions.reset()

        XCTAssertNoThrow(try Amplify.Predictions.configure(using: config))
    }

    /// Test that Amplify logs a warning if it encounters a plugin configuration key without a corresponding plugin
    ///
    /// - Given:
    ///   - A configuration with a nonexistent plugin key specified
    /// - When:
    ///    - I invoke `Amplify.configure()`
    /// - Then:
    ///    - I should see a log warning
    ///
    func testWarnsOnMissingPlugin() throws {
        let warningReceived = expectation(description: "Warning message received")

        let loggingPlugin = MockLoggingCategoryPlugin()
        loggingPlugin.listeners.append { message in
            if message.starts(with: "warn(_:): No plugin found") {
                warningReceived.fulfill()
            }
        }
        let loggingConfig = LoggingCategoryConfiguration(
            plugins: [loggingPlugin.key: true]
        )
        try Amplify.add(plugin: loggingPlugin)

        let categoryConfig = PredictionsCategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig, predictions: categoryConfig)

        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 0.1)
    }

    /// Test if adding a plugin after configuration throws an error
    ///
    /// - Given: Amplify is configured
    /// - When:
    ///    - Add  is called for Predictions category
    /// - Then:
    ///    - Should throw an exception
    ///
    func testAddAfterConfigureThrowsError() throws {
        let plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: config)

        try Amplify.configure(amplifyConfig)

        XCTAssertThrowsError(
            try Amplify.add(plugin: plugin),
            "configure() an already configured plugin should throw")
        { error in
            guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                return
            }
        }

    }
}
