//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSS3
import Amplify

@testable import AWSS3StoragePlugin

class StorageListResultTests: XCTestCase {

    /// Given: A valid S3 object and a non-empty prefix
    /// When: A `StorageListResult.Item` is created from these
    /// Then: The newly-created Item's key does not include the prefix and the rest of its properties are the same as the S3 object's
    func testObjectNonEmptyValidPrefix() throws {
        let prefix = "public/" + UUID().uuidString + "/"
        let fileName = "\(UUID().uuidString).txt"
        let key = prefix + fileName
        let object = S3ClientTypes.Object(eTag: UUID().uuidString,
                                          key: key,
                                          lastModified: Date(),
                                          size: Int.random(in: 512..<1024)
        )
        let item = try StorageListResult.Item(s3Object: object, prefix: prefix)
        XCTAssertEqual(item.key, fileName)
        XCTAssertEqual(item.eTag, object.eTag)
        XCTAssertEqual(item.lastModified, object.lastModified)
        XCTAssertEqual(item.size, object.size)
    }

    /// Given: A valid S3 object and a non-empty, but invalid, prefix
    /// When: A `StorageListResult.Item` is created from these
    /// Then: The newly-created Item's key is empty and the rest of its properties are the same as the S3 object's
    func testObjectNonEmptyInvalidPrefix() throws {
        // TODO: Confirm this behavior is acceptable, this test illustrates what is currently implemented but could cause bad (empty) object keys.
        let prefix = "public/" + UUID().uuidString + "/"
        let key = "\(UUID().uuidString).txt"
        let object = S3ClientTypes.Object(eTag: UUID().uuidString,
                                          key: key,
                                          lastModified: Date(),
                                          size: Int.random(in: 512..<1024)
        )
        let item = try StorageListResult.Item(s3Object: object, prefix: prefix)
        XCTAssertEqual(item.key, "")
        XCTAssertEqual(item.eTag, object.eTag)
        XCTAssertEqual(item.lastModified, object.lastModified)
        XCTAssertEqual(item.size, object.size)
    }

    /// Given: A valid S3 object and an prefix
    /// When: A `StorageListResult.Item` is created from these
    /// Then: All of the newly-created Item's properties are the same as the S3 object's
    func testObjectEmptyPrefix() throws {
        let object = S3ClientTypes.Object(eTag: UUID().uuidString,
                                          key: UUID().uuidString,
                                          lastModified: Date(),
                                          size: Int.random(in: 512..<1024)
        )
        let item = try StorageListResult.Item(s3Object: object, prefix: "")
        XCTAssertEqual(item.key, object.key)
        XCTAssertEqual(item.eTag, object.eTag)
        XCTAssertEqual(item.lastModified, object.lastModified)
        XCTAssertEqual(item.size, object.size)
    }

    /// Given: A malformed S3 object missing its `key`
    /// When: A `StorageListResult.Item` is created from this S3 object
    /// Then: An error is thrown
    func testObjectMissingKey() throws {
        let object = S3ClientTypes.Object()
        do {
            let _ = try StorageListResult.Item(s3Object: object, prefix: "")
            XCTFail("Expecting exception")
        } catch {
            let description = String(describing: error)
            XCTAssertTrue(description.contains("Missing key in response"), description)
        }
    }

    /// Given: A malformed S3 object missing its `eTag`
    /// When: A `StorageListResult.Item` is created from this S3 object
    /// Then: An error is thrown
    func testObjectMissingETag() throws {
        let object = S3ClientTypes.Object(key: UUID().uuidString)
        do {
            let _ = try StorageListResult.Item(s3Object: object, prefix: "")
            XCTFail("Expecting exception")
        } catch {
            let description = String(describing: error)
            XCTAssertTrue(description.contains("Missing eTag in response"), description)
        }
    }

    /// Given: A malformed S3 object missing its `lastModified`
    /// When: A `StorageListResult.Item` is created from this S3 object
    /// Then: An error is thrown
    func testObjectMissingLastModified() throws {
        let object = S3ClientTypes.Object(eTag: UUID().uuidString, key: UUID().uuidString)
        do {
            let _ = try StorageListResult.Item(s3Object: object, prefix: "")
            XCTFail("Expecting exception")
        } catch {
            let description = String(describing: error)
            XCTAssertTrue(description.contains("Missing lastModified in response"), description)
        }
    }
}
