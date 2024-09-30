//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import ClientRuntime
import Foundation
import XCTest
import AWSS3

class S3EmptyBody404Tests: S3XCTestCase {

    // Test ensures that an S3 request that produces a 404 response with no body gets
    // returned to the caller with a NotFound service error.
    //
    // This behavior requires a S3 customization to handle correctly.  The customization currently resides at:
    // Sources/Core/AWSClientRuntime/Errors/RestXMLError+AWS.swift
    // If the customization is disabled, the XML parser throws an error `missingRequiredData` which fails
    // this test.
    //
    // The simplest way to reproduce this condition is to call S3 HeadObject on a nonexistent object.
    // Referencing a nonexistent entity on other S3 endpoints, such as getting a nonexistent object
    // or listing a nonexistent bucket, return a 404 error with a service error serialized in an
    // XML body, as expected.
    func test_emptyBody404_correctlyParsesAnEmpty404() async throws {
        do {

            // Perform the S3 HeadObject operation on a nonexistent object.
            // This will cause the 404 error without a body.
            let input = HeadObjectInput(bucket: bucketName, key: UUID().uuidString)
            _ = try await client.headObject(input: input)

            // If an error was not thrown by the HeadObject call, fail the test.
            XCTFail("Request should have thrown a NotFound modeled service error, instead the request succeeded")
        } catch let error as AWSS3.NotFound {

            // The expected error has now been caught.  Verify that the body is empty and the status code is 404.
            XCTAssertTrue(error.httpResponse.body.isEmpty)
            XCTAssertEqual(error.httpResponse.statusCode, .notFound)

            // test passes.
        }

        // If there was any error not caught by the catch clause above, it will be caught by
        // XCTest & fail the test.
    }
}
