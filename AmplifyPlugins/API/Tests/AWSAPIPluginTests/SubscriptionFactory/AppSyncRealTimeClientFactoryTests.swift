//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable import AWSAPIPlugin

class AppSyncRealTimeClientFactoryTests: XCTestCase {

    func testAppSyncRealTimeEndpoint_withAWSAppSyncDomain_returnCorrectRealtimeDomain() {
        let appSyncEndpoint = URL(string: "https://abc.appsync-api.amazonaws.com/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "https://abc.appsync-realtime-api.amazonaws.com/graphql")
        )
    }

    func testAppSyncRealTimeEndpoint_withAWSAppSyncRealTimeDomain_returnTheSameDomain() {
        let appSyncEndpoint = URL(string: "https://abc.appsync-realtime-api.amazonaws.com/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "https://abc.appsync-realtime-api.amazonaws.com/graphql")
        )
    }

    func testAppSyncRealTimeEndpoint_withCustomDomain_returnCorrectRealtimePath() {
        let appSyncEndpoint = URL(string: "https://test.example.com/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "https://test.example.com/graphql/realtime")
        )
    }
}
