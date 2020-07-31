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

    var contextProvider: DevMenuPresentationContextProvider!
    var plugin: LoggingCategoryPlugin!

    override func setUp() {
        contextProvider = MockDevMenuContextProvider()
        plugin = AWSUnifiedLoggingPlugin()
        Amplify.enableDevMenu(contextProvider: contextProvider)
    }

    func testAmplifyInit() {
        #if DEBUG
            XCTAssertTrue(Amplify.isDevMenuEnabled())
        #else
            XCTAssertFalse(Amplify.isDevMenuEnabled())
        #endif
    }

    func testLoggingCategoryPlugin() {
        #if DEBUG
            let devMenuPlugin = Amplify.getLoggingCategoryPlugin(loggingPlugin: plugin)
            XCTAssertTrue(devMenuPlugin is PersistentLoggingPlugin)
        #else
            let devMenuPlugin = Amplify.getLoggingCategoryPlugin(loggingPlugin: plugin)
            XCTAssertFalse(devMenuPlugin is PersistentLoggingPlugin)
        #endif
    }

    override func tearDown() {
        Amplify.disableDevMenu()
    }
}
