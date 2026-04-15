//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSS3StoragePlugin

class AWSStorageGetURLOptionsTests: XCTestCase {

    // MARK: - Default initializer (no arguments)

    func testDefaultInitializerSetsMethodToGet() {
        let options = AWSStorageGetURLOptions()

        XCTAssertEqual(options.method, .get)
    }

    func testDefaultInitializerSetsValidateObjectExistenceToFalse() {
        let options = AWSStorageGetURLOptions()

        XCTAssertFalse(options.validateObjectExistence)
    }

    // MARK: - Full initializer with all parameters

    func testFullInitializerSetsAllProperties() {
        let options = AWSStorageGetURLOptions(
            validateObjectExistence: true,
            method: .put
        )

        XCTAssertTrue(options.validateObjectExistence)
        XCTAssertEqual(options.method, .put)
    }

    func testFullInitializerWithGetMethod() {
        let options = AWSStorageGetURLOptions(
            validateObjectExistence: false,
            method: .get
        )

        XCTAssertFalse(options.validateObjectExistence)
        XCTAssertEqual(options.method, .get)
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

    // MARK: - StorageAccessMethod enum

    func testStorageAccessMethodGetEquality() {
        let method: StorageAccessMethod = .get
        XCTAssertEqual(method, StorageAccessMethod.get)
    }

    func testStorageAccessMethodPutEquality() {
        let method: StorageAccessMethod = .put
        XCTAssertEqual(method, StorageAccessMethod.put)
    }
}
