//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin

class AWSHTTPURLResponseTests: XCTestCase {

    func testAWSHTTPURLResponse() throws {
        let body = "responseBody".data(using: .utf8)
        let httpResponse = HTTPURLResponse(url: URL(string: "dummyString")!,
                                           statusCode: 200,
                                           httpVersion: "1.1",
                                           headerFields: ["key1": "value1",
                                                          "key2": "value2"])!
        if let response = AWSHTTPURLResponse(response: httpResponse, body: body) {
            XCTAssertNotNil(response.body)
            XCTAssertNotNil(response.url)
            XCTAssertNil(response.mimeType)
            XCTAssertEqual(response.expectedContentLength, -1)
            XCTAssertNil(response.textEncodingName)
            XCTAssertNotNil(response.suggestedFilename)
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields.count, 2)

            XCTAssertNotNil(response.value(forHTTPHeaderField: "key1"))
            XCTAssertNotNil(response.value(forHTTPHeaderField: "key2"))
        } else {
            XCTFail("Failed to initialize `AWSHTTPURLResponse`")
        }
    }

    func testAWSHTTPURLResponseNSCoding() {
        let body = "responseBody".data(using: .utf8)
        let httpResponse = HTTPURLResponse(url: URL(string: "dummyString")!,
                                           statusCode: 200,
                                           httpVersion: "1.1",
                                           headerFields: ["key1": "value1",
                                                          "key2": "value2"])!
        guard let response = AWSHTTPURLResponse(response: httpResponse, body: body) else {
            XCTFail("Failed to initialize `AWSHTTPURLResponse`")
            return
        }
        let data : Data
        do {
            data = try NSKeyedArchiver.archivedData(withRootObject: response, requiringSecureCoding: false)
            XCTAssertNotNil(data)
        } catch (let error) {
            XCTFail("Failed to archive data : \(error)")
            return
        }
        
        do {
            guard let unarchivedResponse = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? AWSHTTPURLResponse else {
                XCTFail("Failure while unarchiving")
                return
            }
            XCTAssertNotNil(unarchivedResponse)
            XCTAssertNotNil(unarchivedResponse.body)
            XCTAssertNotNil(unarchivedResponse.url)
            XCTAssertNil(unarchivedResponse.mimeType)
            XCTAssertEqual(unarchivedResponse.expectedContentLength, -1)
            XCTAssertNil(unarchivedResponse.textEncodingName)
            XCTAssertNotNil(unarchivedResponse.suggestedFilename)
            XCTAssertEqual(unarchivedResponse.statusCode, 200)
            XCTAssertEqual(unarchivedResponse.allHeaderFields.count, 2)
        } catch (let error) {
            XCTFail("Failed to unarchive `AWSHTTPURLResponse` data \(error)")
            return
        }
    }
}
