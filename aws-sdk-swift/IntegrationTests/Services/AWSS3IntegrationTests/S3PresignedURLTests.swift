//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
import AWSS3

class S3PresignedURLTests: S3XCTestCase {

    func test_getObject_getsObjectWithPresignedURL() async throws {
        let originalData = UUID().uuidString
        let key = UUID().uuidString
        try await putObject(body: originalData, key: key)
        let input = GetObjectInput(bucket: bucketName, key: key)
        let url = try await client.presignedURLForGetObject(input: input, expiration: 600.0)
        let data = try await perform(urlRequest: URLRequest(url: url))
        XCTAssertEqual(Data(originalData.utf8), data)
    }

    func test_getObject_urlEncodesInputMembers() async throws {
        let key = UUID().uuidString
        let originalIfMatch = UUID().uuidString
        let originalIfNoneMatch = UUID().uuidString
        let input = GetObjectInput(bucket: bucketName, ifMatch: originalIfMatch, ifNoneMatch: originalIfNoneMatch, key: key)
        let url = try await client.presignedURLForGetObject(input: input, expiration: 600.0)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        XCTAssertNotNil(components?.queryItems?.first(where: { $0.name == "IfMatch" && $0.value == originalIfMatch }))
        XCTAssertNotNil(components?.queryItems?.first(where: { $0.name == "IfNoneMatch" && $0.value == originalIfNoneMatch }))
    }
}
