//
//  RealtimeGatewayURLInterceptorTests.swift
//  AppSyncSubscriptionClientTests
//
//  Created by Law, Michael on 2/19/20.
//  Copyright © 2020 amazonaws. All rights reserved.
//

import XCTest
import AppSyncSubscriptionClient

class RealtimeGatewayURLInterceptorTests: XCTestCase {

    var realtimeGatewayURLInterceptor: RealtimeGatewayURLInterceptor!

    override func setUp() {
        realtimeGatewayURLInterceptor = RealtimeGatewayURLInterceptor()
    }

    func testInterceptRequest() {
        let url = URL(string: "http://xxxc.appsync-api.ap-southeast-2.amazonaws.com/sd")!
        let request = AppSyncConnectionRequest(url: url)
        let changedRequest = realtimeGatewayURLInterceptor.interceptConnection(request, for: url)
        XCTAssertEqual(changedRequest.url.scheme, "wss", "Scheme should be wss")
        XCTAssertTrue(changedRequest.url.absoluteString.contains("appsync-realtime-api"),
                      "URL should contain the realtime part")
    }

}
