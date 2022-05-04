//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSLocation
import Foundation
import XCTest

@testable import AWSLocationGeoPlugin

public class MockAWSLocation: AWSLocationBehavior {

    // MARK: - Location Client
    var locationClient: LocationClient
    
    // MARK: - Method call counts for AWSLocation
    var getEscapeHatchCalled = 0
    var searchPlaceIndexForTextCalled = 0
    var searchPlaceIndexForPositionCalled = 0

    // MARK: - Method arguments for AWSLocation
    var searchPlaceIndexForTextRequest: SearchPlaceIndexForTextInput?
    var searchPlaceIndexForPositionRequest: SearchPlaceIndexForPositionInput?

    public init(pluginConfig: AWSLocationGeoPluginConfiguration) throws {
        self.locationClient = try LocationClient(config: MockAWSClientConfiguration(config: pluginConfig))
    }

    public func getEscapeHatch() -> LocationClient {
        getEscapeHatchCalled += 1
        return self.locationClient
    }
}

extension MockAWSLocation {
    public func verifyGetEscapeHatch() {
        XCTAssertEqual(getEscapeHatchCalled, 1)
    }

    public func verifySearchPlaceIndexForText(_ request: SearchPlaceIndexForTextInput) {
        XCTAssertEqual(searchPlaceIndexForTextCalled, 1)
        guard let receivedRequest = searchPlaceIndexForTextRequest else {
            XCTFail("Did not receive request.")
            return
        }
        XCTAssertNotNil(receivedRequest.indexName)
        if let indexName = request.indexName {
            XCTAssertEqual(receivedRequest.indexName, indexName)
        }
        XCTAssertEqual(receivedRequest.text, request.text)
        XCTAssertEqual(receivedRequest.biasPosition, request.biasPosition)
        XCTAssertEqual(receivedRequest.filterBBox, request.filterBBox)
        XCTAssertEqual(receivedRequest.filterCountries, request.filterCountries)
        XCTAssertEqual(receivedRequest.maxResults, request.maxResults)
    }

    public func verifySearchPlaceIndexForPosition(_ request: SearchPlaceIndexForPositionInput) {
        XCTAssertEqual(searchPlaceIndexForPositionCalled, 1)
        guard let receivedRequest = searchPlaceIndexForPositionRequest else {
            XCTFail("Did not receive request.")
            return
        }
        XCTAssertNotNil(receivedRequest.indexName)
        if let indexName = request.indexName {
            XCTAssertEqual(receivedRequest.indexName, indexName)
        }
        XCTAssertEqual(receivedRequest.position, request.position)
        XCTAssertEqual(receivedRequest.maxResults, request.maxResults)
    }
}
