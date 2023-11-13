//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import AWSPluginsCore
@testable import AWSLocationGeoPlugin

struct MockCredentialsProvider: CredentialsProvider {
    func fetchCredentials() async throws -> AWSPluginsCore.Credentials {
        .init(
            accessKey: "key",
            secret: "secret",
            expirationTimeout: .init(),
            sessionToken: "token"
        )
    }
}

extension CredentialsProvider where Self == MockCredentialsProvider {
    static var mock: Self { .init() }
}

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
        self.locationClient = LocationClient(
            configuration: .init(
                region: pluginConfig.regionName,
                credentialsProvider: .mock,
                encoder: .init(),
                decoder: .init()
            )
        )
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
