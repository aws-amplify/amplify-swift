//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AWSCognitoAuthPluginAppSyncSignerTests: XCTestCase {

    /// Tests translating the URLRequest to the SDKRequest
    /// The translation should account for expected fields, as asserted in the test.
    func testCreateAppSyncSdkHttpRequestBuilder() throws {
        var urlRequest = URLRequest(url: URL(string: "http://graphql.com")!)
        urlRequest.httpMethod = "post"
        let dataObject = Data()
        urlRequest.httpBody = dataObject
        guard let sdkRequestBuilder = try AWSCognitoAuthPlugin.createAppSyncSdkHttpRequestBuilder(urlRequest: urlRequest) else {
            XCTFail("Could not create SDK request")
            return
        }

        let request = sdkRequestBuilder.build()
        XCTAssertEqual(request.host, "graphql.com")
        XCTAssertEqual(request.path, "")
        XCTAssertEqual(request.queryItems, [])
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.endpoint.port, 443)
        XCTAssertEqual(request.endpoint.protocolType, .https)
        XCTAssertEqual(request.endpoint.headers.headers, [.init(name: "host", value: "graphql.com")])
        guard case let .data(data) = request.body else {
            XCTFail("Unexpected body")
            return
        }
        XCTAssertEqual(data, dataObject)
    }
}
