//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSS3

/// Test S3 operations that use Content-MD5 header by using S3::deleteObjects API
final class S3ContentMD5HeaderTests: S3XCTestCase {
    var objectKeys: [String] = []
    let objectContent = "filler-content"

    override func setUp() async throws {
        try await super.setUp()
        // Generate 3 UUIDs to use as object keys and save them
        for _ in 1...3 {
            objectKeys.append("key-\(UUID().uuidString.split(separator: "-").first!.lowercased())")
        }
    }

    func testDeleteObjects() async throws {
        // Upload 3 objects
        for key in objectKeys {
            try await putObject(body: objectContent, key: key)
        }

        // Delete the 3 objects at once using DeleteObjects
        let input = DeleteObjectsInput(
            bucket: bucketName,
            delete: S3ClientTypes.Delete(
                objects: objectKeys.map { S3ClientTypes.ObjectIdentifier(key: $0) }
            )
        )
        let result = try await client.deleteObjects(input: input)

        // Confirm all deletions succeeded
        XCTAssertNil(result.errors)
        XCTAssertEqual(result.deleted?.count, objectKeys.count)
    }
}
