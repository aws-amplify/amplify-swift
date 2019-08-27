//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import CwlPreconditionTesting
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginTests: XCTestCase {
    func testNotConfiguredThrowsExceptionForGet() {
        let storagePlugin = AWSS3StoragePlugin()

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.get(key: "key", options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForGetWithLocalUrl() {
        let storagePlugin = AWSS3StoragePlugin()
        let url = URL(fileURLWithPath: "path")

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.get(key: "key", local: url, options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForPut() {
        let storagePlugin = AWSS3StoragePlugin()
        let data = Data()

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.put(key: "key", data: data, options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForPutWithLocalUrl() {
        let storagePlugin = AWSS3StoragePlugin()
        let url = URL(fileURLWithPath: "path")

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.put(key: "key", local: url, options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForRemove() {
        let storagePlugin = AWSS3StoragePlugin()

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.remove(key: "key", options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForList() {
        let storagePlugin = AWSS3StoragePlugin()

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.list(options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    // StoragePlugin Get API Tests
    func testPluginGet() {
        // Arrange
        let storagePlugin = AWSS3StoragePlugin()
        let service = MockAWSS3StorageService()
        let queue = MockOperationQueue()
        let bucket = "bucket"
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let key = "key"
        let expectedKey = "public/" + key

        // Act
        let result = storagePlugin.get(key: key, options: nil, onComplete: nil)

        // Assert
        XCTAssertNotNil(result)
        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation not castable to ")
            return
        }
        let request = awss3StorageGetOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.bucket, bucket)
        XCTAssertEqual(request.key, expectedKey)
        XCTAssertNil(request.fileURL)
    }

    func testPluginGetWithOptions() {

    }

    func testPluginGetWithLocalFile() {
        // Arrange
        let storagePlugin = AWSS3StoragePlugin()
        let service = MockAWSS3StorageService()
        let queue = MockOperationQueue()
        let bucket = "bucket"
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let key = "key"
        let expectedKey = "public/" + key
        let url = URL(fileURLWithPath: "path")

        // Act
        let result = storagePlugin.get(key: key, local: url, options: nil, onComplete: nil)

        // Assert
        XCTAssertNotNil(result)

        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation not castable to ")
            return
        }
        let request = awss3StorageGetOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.bucket, bucket)
        XCTAssertEqual(request.key, expectedKey)
        XCTAssertEqual(request.fileURL, url)
    }

    // StoragePlugin Get URL Tests
    func testAWSS3StoragePluginGet_Error() {

    }

    func testAWSS3StoragePluginGet_WithXOptions() {
        // mostly same as above
    }

    func AWSS3StorageGetOperation_UnitTesting() {
        // Arrange
        // set up an operation with the request object
        // operation needs the storageLayer to do its work... so we need to pass by reference to it.
        // AWSS3StorageLayer will then internally retrieve the singleton's and do the work.
        // AWSS3StorageLayer protocol will abstract away which dependency we are wrapping,
        // ie. StorageLayer protocol has download/upload/getUrl/list/remove/and more can be added.
        // set up an operation with the storageLayer.

        // Act
        // can we simply do operation.start() -> call the main method?
        // this means MockAWSS3StorageLayer will be an instance we pass into init which we can assert that
        // things are called

        // Assert
    }

    // functional or integration in this sense uses real storage layer.
    // so we need to create a real instance of the storagelayer with real data.
    func testAWSS3StorageGetOperation_Functional() {
        // Arrange
        // create instance of AWss3storageLayer with real data
        // create request for operation
        // create oncomplete handler
        // create operation with above

        // Act
        // operation.start? or queue it up..

        // Assert
        // make sure that the assert on completion worked
        // make sure progress handler gets called?
        // make sure we got the data back and it is valid
    }

    func testAWSS3StorageLayer_download_UnitTest() {
        // so here we are constructing a real awss3storagelayer
        // and a mock of transferUtility.

        // now how do we mock transferUtility if the storageLayer is init with singletons?
        // can we create MockAWSS3TransferUtility?
        // when(AWSS3TransferUtility.s3TransferUtility(forKey:key).thenReturn(mockAwsS3TransferUtility)?
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
