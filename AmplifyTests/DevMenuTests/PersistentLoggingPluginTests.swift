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

class PersistentLoggingPluginTests: XCTestCase {

    let provider = MockDevMenuContextProvider()

    override func setUp() {
        do {
            Amplify.enableDevMenu(contextProvider: provider)

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

    /// Check for logwrapper type in persistentloggingplugin
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - I check for the type of logwrapper type in persistentloggingplugin
    /// - Then:
    ///    - I should get PersistentLogWrapper

    func testPersistentLogWrapperType() throws {
        let devMenuPlugin = try Amplify.Logging.getPlugin(for: DevMenuStringConstants.persistentLoggingPluginKey)
        XCTAssertTrue(devMenuPlugin.default is PersistentLogWrapper)
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }
}
#endif
