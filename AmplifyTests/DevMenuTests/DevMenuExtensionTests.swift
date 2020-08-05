//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

@available(iOS 13.0.0, *)
class DevMenuExtensionTests: XCTestCase {

    override func setUp() {
        Amplify.enableDevMenu(contextProvider: MockDevMenuContextProvider())
        do {
            try Amplify.configure()
        } catch {
            print(error)
        }
    }

    ///  Test if dev menu is enabled
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - I check whether dev menu is enabled
    /// - Then:
    ///    -  isDevMenuEnabled() should return true
    ///
    func testAmplifyInit() {
        XCTAssertTrue(Amplify.isDevMenuEnabled())
    }

    /// Test if PersistentLoggingPlugin is returned on enabling dev menu
    ///
    /// - Given:  Amplify is configured with Dev Menu enabled
    /// - When:
    ///    - I check the type of LoggingCategoryPlugin
    /// - Then:
    ///    - It should be of PersistentLoggingPlugin type
    ///
    func testLoggingCategoryPlugin() {
        do {
            let devMenuPlugin = try Amplify.Logging.getPlugin(for: DevMenuStringConstants.persistentLoggingPluginKey)
            XCTAssertTrue(devMenuPlugin is PersistentLoggingPlugin)
        } catch {
            print(error)
        }
    }

    override func tearDown() {
        Amplify.reset()
    }
}
