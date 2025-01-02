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
            URL(string: "wss://abc.appsync-realtime-api.amazonaws.com/graphql")
        )

        let appSyncEndpointCN = URL(string: "https://abc.appsync-api.amazonaws.com.cn/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(appSyncEndpointCN),
            URL(string: "wss://abc.appsync-realtime-api.amazonaws.com.cn/graphql")
        )
    }

    func testAppSyncRealTimeEndpoint_withAWSAppSyncRealTimeDomain_returnTheSameDomain() {
        let appSyncEndpoint = URL(string: "wss://abc.appsync-realtime-api.amazonaws.com/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "wss://abc.appsync-realtime-api.amazonaws.com/graphql")
        )

        let appSyncEndpointCN = URL(string: "wss://abc.appsync-realtime-api.amazonaws.com.cn/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(appSyncEndpointCN),
            URL(string: "wss://abc.appsync-realtime-api.amazonaws.com.cn/graphql")
        )
    }

    func testAppSyncRealTimeEndpoint_withCustomDomain_returnCorrectRealtimePath() {
        let appSyncEndpoint = URL(string: "https://test.example.com/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "https://test.example.com/graphql/realtime")
        )

        let appSyncEndpointCN = URL(string: "https://test.example.com.cn/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(appSyncEndpointCN),
            URL(string: "https://test.example.com.cn/graphql/realtime")
        )
    }

    func testAppSyncApiEndpoint_withAWSAppSyncRealTimeDomain_returnCorrectApiDomain() {
        let appSyncEndpoint = URL(string: "wss://abc.appsync-realtime-api.amazonaws.com/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncApiEndpoint(appSyncEndpoint),
            URL(string: "https://abc.appsync-api.amazonaws.com/graphql")
        )

        let appSyncEndpointCN = URL(string: "wss://abc.appsync-realtime-api.amazonaws.com.cn/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncApiEndpoint(appSyncEndpointCN),
            URL(string: "https://abc.appsync-api.amazonaws.com.cn/graphql")
        )
    }

    func testAppSyncApiEndpoint_withAWSAppSyncApiDomain_returnTheSameDomain() {
        let appSyncEndpoint = URL(string: "https://abc.appsync-api.amazonaws.com/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncApiEndpoint(appSyncEndpoint),
            URL(string: "https://abc.appsync-api.amazonaws.com/graphql")
        )

        let appSyncEndpointCN = URL(string: "https://abc.appsync-api.amazonaws.com.cn/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncApiEndpoint(appSyncEndpointCN),
            URL(string: "https://abc.appsync-api.amazonaws.com.cn/graphql")
        )
    }

    func testAppSyncApiEndpoint_withCustomDomain_returnCorrectRealtimePath() {
        let appSyncEndpoint = URL(string: "https://test.example.com/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncApiEndpoint(appSyncEndpoint),
            URL(string: "https://test.example.com/graphql")
        )

        let appSyncEndpointCN = URL(string: "https://test.example.com.cn/graphql")!
        XCTAssertEqual(
            AppSyncRealTimeClientFactory.appSyncApiEndpoint(appSyncEndpointCN),
            URL(string: "https://test.example.com.cn/graphql")
        )
    }
}
