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
    
    func testSearchForText() async {
        let text = "test"
        let expectedMessage = "search(for text:\(text))"
        var expectedFunctionCalled = false
        plugin.listeners.append { message in
            print(message)
            if message == expectedMessage {
                expectedFunctionCalled = true
            }
        }
        do {
            _ = try await geo.search(for: text, options: nil)
            XCTAssertTrue(expectedFunctionCalled)
        } catch {
            XCTFail("Error: \(error)")
        }
    }
    
    func testSearchForCoords() async {
        let coordinates = Geo.Coordinates(latitude: 0, longitude: 0)
        let expectedMessage = "search(for coordinates:\(coordinates))"
        var expectedFunctionCalled = false
        plugin.listeners.append { message in
            print(message)
            if message == expectedMessage {
                expectedFunctionCalled = true
            }
        }
        do {
            _ = try await geo.search(for: coordinates, options: nil)
            XCTAssertTrue(expectedFunctionCalled)
        } catch {
            XCTFail("Error: \(error)")
        }
    }
    
    func testGetAvailableMaps() async {
        let expectedMessage = "availableMaps"
        var expectedFunctionCalled = false
        plugin.listeners.append { message in
            print(message)
            if message == expectedMessage {
                expectedFunctionCalled = true
            }
        }

        do {
            _ = try await geo.availableMaps()
            XCTAssertTrue(expectedFunctionCalled)
        } catch {
            XCTFail("Error: \(error)")
        }
    }
    
    func testGetDefaultMap() async {
        let expectedMessage = "defaultMap"
        var expectedFunctionCalled = false
        plugin.listeners.append { message in
            print(message)
            if message == expectedMessage {
                expectedFunctionCalled = true
            }
        }

        do {
            _ = try await geo.defaultMap()
            XCTAssertTrue(expectedFunctionCalled)
        } catch {
            XCTFail("Error: \(error)")
        }
    }
}
