//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class AuthPluginSelectorFactoryTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
    }

    func testAddingSelectorFactoryBeforeFirstPluginWorks() throws {
        let factory = MockAuthPluginSelectorFactory()

        let addShouldBeInvokedOnFactory = expectation(description: "`add` should be invoked on factory")
        factory.listeners.append { message in
            if message == "add(plugin:)" {
                addShouldBeInvokedOnFactory.fulfill()
            }
        }

        try Amplify.Auth.set(pluginSelectorFactory: factory)

        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        waitForExpectations(timeout: 1.0)
    }

    func testNewlyAddedSelectorFactoryIsNotifiedOfAlreadyAddedPlugins() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let factory = MockAuthPluginSelectorFactory()

        let addShouldBeInvokedOnFactory = expectation(description: "`add` should be invoked on factory")
        factory.listeners.append { message in
            if message == "add(plugin:)" {
                addShouldBeInvokedOnFactory.fulfill()
            }
        }

        try Amplify.Auth.set(pluginSelectorFactory: factory)
        waitForExpectations(timeout: 1.0)
    }

    func testAddingPluginNotifiesPreviouslyAddedSelectorFactory() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let factory = MockAuthPluginSelectorFactory()

        let addShouldBeInvokedOnFactory = expectation(description: "`add` should be invoked on factory")
        addShouldBeInvokedOnFactory.expectedFulfillmentCount = 2
        factory.listeners.append { message in
            if message == "add(plugin:)" {
                addShouldBeInvokedOnFactory.fulfill()
            }
        }

        try Amplify.Auth.set(pluginSelectorFactory: factory)

        let plugin2 = MockSecondAuthCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        waitForExpectations(timeout: 1.0)
    }

    func testRemovingExistingPluginNotifiesFactory() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let factory = MockAuthPluginSelectorFactory()

        let removeShouldBeInvokedOnFactory = expectation(description: "`remove` should be invoked on factory")
        factory.listeners.append { message in
            if message == "removePlugin(for:)" {
                removeShouldBeInvokedOnFactory.fulfill()
            }
        }

        try Amplify.Auth.set(pluginSelectorFactory: factory)

        Amplify.Auth.removePlugin(for: plugin1.key)

        waitForExpectations(timeout: 1.0)
    }

    func testRemovingNonexistantPluginNotifiesFactory() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let factory = MockAuthPluginSelectorFactory()

        let removeShouldBeInvokedOnFactory = expectation(description: "`remove` should be invoked on factory")
        factory.listeners.append { message in
            if message == "removePlugin(for:)" {
                removeShouldBeInvokedOnFactory.fulfill()
            }
        }

        try Amplify.Auth.set(pluginSelectorFactory: factory)

        Amplify.Auth.removePlugin(for: "ZZZ_NON_EXISTENT_KEY")

        waitForExpectations(timeout: 1.0)
    }

}
