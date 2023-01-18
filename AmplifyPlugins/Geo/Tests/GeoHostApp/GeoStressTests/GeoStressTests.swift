//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSLocationGeoPlugin

final class GeoStressTests: XCTestCase {
    let timeout = 30.0
    let searchText = "coffee shop"
    let coordinates = Geo.Coordinates(latitude: 39.7392, longitude: -104.9903)
    let concurrencyLimit = 50
    let amplifyConfigurationFile = "testconfiguration/AWSAmplifyStressTests-amplifyconfiguration"

    override func setUp() {
        continueAfterFailure = false
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSLocationGeoPlugin())
            let configuration = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(configuration)
        } catch {
            XCTFail("Failed to initialize and configure Amplify: \(error)")
        }
        XCTAssertNotNil(Amplify.Geo.plugin)
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }
    
    // MARK: - Stress Tests
    
    /// Test if concurrent execution of search(for: text) is successful
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke search(for: text) from 50 tasks concurrently
    /// - Then:
    ///    - Place results are returned.
    ///
    func testMultipleSearchForText() async {
        let successExpectation = asyncExpectation(description: "searchForText was successful", expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                do {
                    let options = Geo.SearchForTextOptions(area: .near(coordinates))
                    let places = try await Amplify.Geo.search(for: searchText, options: options)
                    XCTAssertFalse(places.isEmpty)
                    await successExpectation.fulfill()
                } catch {
                    XCTFail("Failed with error: \(error)")
                }
            }
        }
        
        await waitForExpectations([successExpectation], timeout: timeout)
    }
    
    /// Test if concurrent execution of search(for: coordinates) is successful
    /// - Given: Geo plugin with a valid configuration.
    /// - When:
    ///    - I invoke search(for: coordinates) from 50 tasks concurrently
    /// - Then:
    ///    - Place results are returned.
    ///
    func testMultipleSearchForCoordinates() async {
        let successExpectation = asyncExpectation(description: "searchForCoordinates was successful", expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                do {
                    let places = try await Amplify.Geo.search(for: coordinates, options: nil)
                    XCTAssertFalse(places.isEmpty)
                    XCTAssertNotNil(places.first?.coordinates)
                    await successExpectation.fulfill()
                } catch {
                    XCTFail("Failed with error: \(error)")
                }
            }
        }
        
        await waitForExpectations([successExpectation], timeout: timeout)
    }

}
