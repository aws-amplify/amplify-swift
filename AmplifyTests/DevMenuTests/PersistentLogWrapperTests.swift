//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(UIKit)
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class PersistentLogWrapperTests: XCTestCase {

    let provider = MockDevMenuContextProvider()

    override func setUp() async throws {
        do {
            await Amplify.enableDevMenu(contextProvider: provider)

            /// After await Amplify.reset() is called in teardown(), Amplify.configure() doesn't
            /// initialize the plugin for LoggingCategory . This doesn't call Amplify.getLoggingCategoryPlugin()
            /// and the plugin is not updated to PersistentLoggingPlugin. Making a call to
            /// add() so that configure() updates the plugin
            try Amplify.add(plugin: AWSUnifiedLoggingPlugin())

            try Amplify.configure(AmplifyConfiguration())
        } catch {
            XCTFail("Failed \(error)")
        }
    }

    /// Test error function
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - error(message: String) method is called with Amplify.Logging
    /// - Then:
    ///    -  LogHistory should not be empty and must contain a
    ///    single log item with loglevel as error and message the same as passed to error()

    func testError() {
        Amplify.Logging.error("Error message")
        let logHistory: [LogEntryItem] = LogEntryHelper.getLogHistory()
        XCTAssertTrue(logHistory.count == 1)
        XCTAssertTrue(logHistory[0].logLevel == .error)
        XCTAssertTrue(logHistory[0].message == "Error message")
    }

    /// Test verbose function
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - verbose() method is called with Amplify.Logging
    /// - Then:
    ///    -  LogHistory should not be empty and must contain a
    ///    single log item with loglevel as verbose and message the same as passed to verbose()

    func testVerbose() {
        Amplify.Logging.verbose("Verbose message")
        let logHistory: [LogEntryItem] = LogEntryHelper.getLogHistory()
        XCTAssertTrue(logHistory.count == 1)
        XCTAssertTrue(logHistory[0].logLevel == .verbose)
        XCTAssertTrue(logHistory[0].message == "Verbose message")
    }

    /// Test warn function
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - warn() method is called with Amplify.Logging
    /// - Then:
    ///    -  LogHistory should not be empty and must contain a
    ///    single log item with loglevel as warn and message the same as passed to warn()

    func testWarn() {
        Amplify.Logging.warn("Warn message")
        let logHistory: [LogEntryItem] = LogEntryHelper.getLogHistory()
        XCTAssertTrue(logHistory.count == 1)
        XCTAssertTrue(logHistory[0].logLevel == .warn)
        XCTAssertTrue(logHistory[0].message == "Warn message")
    }

    /// Test info function
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - info() method is called with Amplify.Logging
    /// - Then:
    ///    -  LogHistory should not be empty and must contain a
    ///    single log item with loglevel as info and message the same as passed to info()

    func testInfo() {
        Amplify.Logging.info("Info message")
        let logHistory: [LogEntryItem] = LogEntryHelper.getLogHistory()
        XCTAssertTrue(logHistory.count == 1)
        XCTAssertTrue(logHistory[0].logLevel == .info)
        XCTAssertTrue(logHistory[0].message == "Info message")
    }

    /// Test debug function
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - debug() method is called with Amplify.Logging
    /// - Then:
    ///    -  LogHistory should not be empty and must contain a
    ///    single log item with loglevel as debug and message the same as passed to debug()

    func testDebug() {
        Amplify.Logging.debug("Debug message")
        let logHistory: [LogEntryItem] = LogEntryHelper.getLogHistory()
        XCTAssertTrue(logHistory.count == 1)
        XCTAssertTrue(logHistory[0].logLevel == .debug)
        XCTAssertTrue(logHistory[0].message == "Debug message")
    }

    /// Test log limit of persistentlogwrapper
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - I add logs one more than the limit of log wrapper
    /// - Then:
    ///    -  The log wrapper should retain only logs the same as the log limit and
    ///     first log should be removed

    func testLogLimit() {
        for itemNumber in 1 ... PersistentLogWrapper.logLimit + 1 {
            Amplify.Logging.info("Message \(itemNumber)")
        }
        let logHistory: [LogEntryItem] = LogEntryHelper.getLogHistory()
        XCTAssertTrue(logHistory.count == PersistentLogWrapper.logLimit)
        XCTAssertTrue(logHistory[0].message == "Message 2")
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }
}
#endif
