//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSStorageGetURLOptionsTests: XCTestCase {

    // MARK: - Default initializer (no arguments)

    func testDefaultInitializerSetsMethodToGet() {
        let options = AWSStorageGetURLOptions()

        XCTAssertEqual(options.method, .get)
    }

    func testDefaultInitializerSetsContentTypeToNil() {
        let options = AWSStorageGetURLOptions()

        XCTAssertNil(options.contentType)
    }

    func testDefaultInitializerSetsValidateObjectExistenceToFalse() {
        let options = AWSStorageGetURLOptions()

        XCTAssertFalse(options.validateObjectExistence)
    }

    // MARK: - Full initializer with all parameters

    func testFullInitializerSetsAllProperties() {
        let options = AWSStorageGetURLOptions(
            validateObjectExistence: true,
            method: .put,
            contentType: "application/json"
        )

        XCTAssertTrue(options.validateObjectExistence)
        XCTAssertEqual(options.method, .put)
        XCTAssertEqual(options.contentType, "application/json")
    }

    func testFullInitializerWithGetMethod() {
        let options = AWSStorageGetURLOptions(
            validateObjectExistence: false,
            method: .get,
            contentType: nil
        )

        XCTAssertFalse(options.validateObjectExistence)
        XCTAssertEqual(options.method, .get)
        XCTAssertNil(options.contentType)
    }

    func testFullInitializerDefaultParameters() {
        let options = AWSStorageGetURLOptions(validateObjectExistence: true, method: .put)

        XCTAssertTrue(options.validateObjectExistence)
        XCTAssertEqual(options.method, .put)
        XCTAssertNil(options.contentType)
    }

    // MARK: - Backward-compatible initializer

    func testBackwardCompatibleInitializerSetsValidateObjectExistence() {
        let options = AWSStorageGetURLOptions(validateObjectExistence: true)

        XCTAssertTrue(options.validateObjectExistence)
    }

    func testBackwardCompatibleInitializerDefaultsMethodToGet() {
        let options = AWSStorageGetURLOptions(validateObjectExistence: true)

        XCTAssertEqual(options.method, .get)
    }

    func testBackwardCompatibleInitializerDefaultsContentTypeToNil() {
        let options = AWSStorageGetURLOptions(validateObjectExistence: false)

        XCTAssertNil(options.contentType)
    }

    // MARK: - HTTPMethod enum

    func testHTTPMethodGetRawValue() {
        XCTAssertEqual(AWSStorageGetURLOptions.HTTPMethod.get.rawValue, "GET")
    }

    func testHTTPMethodPutRawValue() {
        XCTAssertEqual(AWSStorageGetURLOptions.HTTPMethod.put.rawValue, "PUT")
    }
}
