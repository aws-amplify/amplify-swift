//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

// Tests that the client behavior API calls pass through from Category to CategoryPlugin
class GeoCategoryClientAPITests: XCTestCase {
    var geo: GeoCategory!
    var plugin: MockGeoCategoryPlugin!

    override func setUp() {
        Amplify.reset()
        plugin = MockGeoCategoryPlugin()
        geo = Amplify.Geo
        let categoryConfiguration = GeoCategoryConfiguration(
            plugins: ["MockGeoCategoryPlugin": true]
        )
        let amplifyConfiguration = AmplifyConfiguration(geo: categoryConfiguration)

        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfiguration)
        } catch let error as AmplifyError {
            XCTFail("setUp failed with error: \(error); \(error.errorDescription); \(error.recoverySuggestion)")
        } catch {
            XCTFail("setup failed with unknown error")
        }

    }

    func testSearchForText() throws {
        let text = "test"
        let expectedMessage = "search(for text:\(text))"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        geo.search(for: text) { _ in }
        waitForExpectations(timeout: 1.0)
    }

    func testSearchForCoords() throws {
        let coordinates = Geo.Coordinates(latitude: 0, longitude: 0)
        let expectedMessage = "search(for coordinates:\(coordinates))"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        geo.search(for: coordinates) { _ in }
        waitForExpectations(timeout: 1.0)
    }

    func testGetAvailableMaps() throws {
        let expectedMessage = "availableMaps"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            print(message)
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        geo.availableMaps { _ in }
        waitForExpectations(timeout: 1.0)
    }

    func testGetDefaultMap() throws {
        let expectedMessage = "defaultMap"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            print(message)
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        geo.defaultMap { _ in }
        waitForExpectations(timeout: 1.0)
    }
}
