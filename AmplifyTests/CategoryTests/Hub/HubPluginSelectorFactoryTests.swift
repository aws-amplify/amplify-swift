//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class HubPluginSelectorFactoryTests: XCTestCase {

//    override func setUp() {
//        await Amplify.reset()
//    }
//
//    func testAddingSelectorFactoryBeforeFirstPluginWorks() throws {
//        let factory = MockHubPluginSelectorFactory()
//
//        let addShouldBeInvokedOnFactory = expectation(description: "`add` should be invoked on factory")
//        factory.listeners.append { message in
//            if message == "add(plugin:)" {
//                addShouldBeInvokedOnFactory.fulfill()
//            }
//        }
//
//        try Amplify.Hub.set(pluginSelectorFactory: factory)
//
//        let plugin1 = MockHubCategoryPlugin()
//        try Amplify.add(plugin: plugin1)
//
//        waitForExpectations(timeout: 1.0)
//    }
//
//    func testNewlyAddedSelectorFactoryIsNotifiedOfAlreadyAddedPlugins() throws {
//        let plugin1 = MockHubCategoryPlugin()
//        try Amplify.add(plugin: plugin1)
//
//        let factory = MockHubPluginSelectorFactory()
//
//        let addShouldBeInvokedOnFactory = expectation(description: "`add` should be invoked on factory")
//        factory.listeners.append { message in
//            if message == "add(plugin:)" {
//                addShouldBeInvokedOnFactory.fulfill()
//            }
//        }
//
//        try Amplify.Hub.set(pluginSelectorFactory: factory)
//        waitForExpectations(timeout: 1.0)
//    }
//
//    func testAddingPluginNotifiesPreviouslyAddedSelectorFactory() throws {
//        let plugin1 = MockHubCategoryPlugin()
//        try Amplify.add(plugin: plugin1)
//
//        let factory = MockHubPluginSelectorFactory()
//
//        let addShouldBeInvokedOnFactory = expectation(description: "`add` should be invoked on factory")
//        addShouldBeInvokedOnFactory.expectedFulfillmentCount = 2
//        factory.listeners.append { message in
//            if message == "add(plugin:)" {
//                addShouldBeInvokedOnFactory.fulfill()
//            }
//        }
//
//        try Amplify.Hub.set(pluginSelectorFactory: factory)
//
//        let plugin2 = MockSecondHubCategoryPlugin()
//        try Amplify.add(plugin: plugin2)
//
//        waitForExpectations(timeout: 1.0)
//    }
//
//    func testRemovingExistingPluginNotifiesFactory() throws {
//        let plugin1 = MockHubCategoryPlugin()
//        try Amplify.add(plugin: plugin1)
//
//        let factory = MockHubPluginSelectorFactory()
//
//        let removeShouldBeInvokedOnFactory = expectation(description: "`remove` should be invoked on factory")
//        factory.listeners.append { message in
//            if message == "removePlugin(for:)" {
//                removeShouldBeInvokedOnFactory.fulfill()
//            }
//        }
//
//        try Amplify.Hub.set(pluginSelectorFactory: factory)
//
//        Amplify.Hub.removePlugin(for: plugin1.key)
//
//        waitForExpectations(timeout: 1.0)
//    }
//
//    func testRemovingNonexistantPluginNotifiesFactory() throws {
//        let plugin1 = MockHubCategoryPlugin()
//        try Amplify.add(plugin: plugin1)
//
//        let factory = MockHubPluginSelectorFactory()
//
//        let removeShouldBeInvokedOnFactory = expectation(description: "`remove` should be invoked on factory")
//        factory.listeners.append { message in
//            if message == "removePlugin(for:)" {
//                removeShouldBeInvokedOnFactory.fulfill()
//            }
//        }
//
//        try Amplify.Hub.set(pluginSelectorFactory: factory)
//
//        Amplify.Hub.removePlugin(for: "ZZZ_NON_EXISTENT_KEY")
//
//        waitForExpectations(timeout: 1.0)
//    }

}
