//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

/// Tests of the default AWSUnifiedLoggingPlugin
///
/// NOTE: Tests in this class invoke log methods with hardcoded strings directly inline with the method call. This is
/// important. The `message` arguments are auto-closures, and we're relying on that fact to determine whether a message
/// is being evaluated or not. In other words, don't assign the message to a variable, and then pass it to the logging
/// method.
class DefaultLoggingPluginTests: XCTestCase {

    override func setUp() async throws {
        await Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    /// Given: An Amplify system configured with default values
    /// When: I invoke Amplify.configure()
    /// Then: I have access to the framework-provided Logging plugin
    func testDefaultPluginAssigned() throws {
        let plugin = try? Amplify.Logging.getPlugin(for: "AWSUnifiedLoggingPlugin")
        XCTAssertNotNil(plugin)
        XCTAssertEqual(plugin?.key, "AWSUnifiedLoggingPlugin")
    }

    /// - Given: A default Amplify configuration
    /// - When:
    ///    - I log messages using `Amplify.Logging`
    /// - Then:
    ///    - It uses the default logging level
    func testUsesDefaultLoggingLevel() {
        // Relies on Amplify.Logging.logLevel defaulting to `.error`

        let errorMessageCorrectlyEvaluated = expectation(description: "error message was correctly evaluated")
        Amplify.Logging.error("error \(errorMessageCorrectlyEvaluated.fulfill())")

        let warnMessageIncorrectlyEvaluated = expectation(description: "warn message was incorrectly evaluated")
        warnMessageIncorrectlyEvaluated.isInverted = true
        Amplify.Logging.warn("warn \(warnMessageIncorrectlyEvaluated.fulfill())")

        let infoMessageIncorrectlyEvaluated = expectation(description: "info message was incorrectly evaluated")
        infoMessageIncorrectlyEvaluated.isInverted = true
        Amplify.Logging.info("info \(infoMessageIncorrectlyEvaluated.fulfill())")

        let debugMessageIncorrectlyEvaluated = expectation(description: "debug message was incorrectly evaluated")
        debugMessageIncorrectlyEvaluated.isInverted = true
        Amplify.Logging.debug("debug \(debugMessageIncorrectlyEvaluated.fulfill())")

        let verboseMessageIncorrectlyEvaluated = expectation(description: "verbose message was incorrectly evaluated")
        verboseMessageIncorrectlyEvaluated.isInverted = true
        Amplify.Logging.verbose("verbose \(verboseMessageIncorrectlyEvaluated.fulfill())")

        waitForExpectations(timeout: 0.1)
    }

    /// - Given: default configuration
    /// - When:
    ///    - I change the global Amplify.Logging.logLevel
    /// - Then:
    ///    - My log statements are evaluated appropriately
    func testRespectsChangedDefaultLogLevel() {
        Amplify.Logging.logLevel = .error

        let warnMessageIncorrectlyEvaluated = expectation(description: "warn message was incorrectly evaluated")
        warnMessageIncorrectlyEvaluated.isInverted = true
        Amplify.Logging.warn("warn \(warnMessageIncorrectlyEvaluated.fulfill())")

        let infoMessageIncorrectlyEvaluated = expectation(description: "info message was incorrectly evaluated")
        infoMessageIncorrectlyEvaluated.isInverted = true
        Amplify.Logging.info("info \(infoMessageIncorrectlyEvaluated.fulfill())")

        Amplify.Logging.logLevel = .warn

        let warnMessageCorrectlyEvaluated = expectation(description: "warn message was correctly evaluated")
        Amplify.Logging.warn("warn \(warnMessageCorrectlyEvaluated.fulfill())")

        let infoMessageIncorrectlyEvaluatedAgain =
            expectation(description: "info message was incorrectly evaluated second time")
        infoMessageIncorrectlyEvaluatedAgain.isInverted = true
        Amplify.Logging.info("info \(infoMessageIncorrectlyEvaluatedAgain.fulfill())")

        waitForExpectations(timeout: 0.1)
    }

    /// Although we can't assert it, the messages in the console log are expected to have different "category" tags
    ///
    /// - Given: default configuration
    /// - When:
    ///    - I obtain a category-specific log
    /// - Then:
    ///    - I can send messages to it
    func testCategorySpecificLog() throws {
        let logger1MessageCorrectlyEvaluated = expectation(description: "logger1 message was correctly evaluated")
        let logger2MessageCorrectlyEvaluated = expectation(description: "logger2 message was correctly evaluated")

        try XCTAssertNoThrowFatalError {
            let logger1 = Amplify.Logging.logger(forCategory: "Logger1")
            let logger2 = Amplify.Logging.logger(forCategory: "Logger2")

            logger1.error("logger1 \(logger1MessageCorrectlyEvaluated.fulfill())")
            logger2.error("logger2 \(logger2MessageCorrectlyEvaluated.fulfill())")
        }

        waitForExpectations(timeout: 0.1)
    }

    /// - Given: default configuration
    /// - When:
    ///    - I obtain category specific logs with different log levels
    /// - Then:
    ///    - Each category-specific log evalutes at the appropriate level
    func testDifferentLoggersWithDifferentLogLevels() {
        let globalMessageCorrectlyEvaluated = expectation(description: "global message was correctly evaluated")
        let logger1MessageCorrectlyEvaluated = expectation(description: "logger1 message was correctly evaluated")
        let logger2MessageIncorrectlyEvaluated = expectation(description: "logger2 message was incorrectly evaluated")
        logger2MessageIncorrectlyEvaluated.isInverted = true

        Amplify.Logging.logLevel = .info
        let logger1 = Amplify.Logging.logger(forCategory: "Logger1", logLevel: .debug)
        let logger2 = Amplify.Logging.logger(forCategory: "Logger2", logLevel: .warn)

        Amplify.Logging.info("global \(globalMessageCorrectlyEvaluated.fulfill())")
        logger1.info("logger1 \(logger1MessageCorrectlyEvaluated.fulfill())")
        logger2.info("logger2 \(logger2MessageIncorrectlyEvaluated.fulfill())")

        waitForExpectations(timeout: 0.1)
    }
}
