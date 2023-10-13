////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsTestCommon
@testable import AWSS3StoragePlugin
@testable import AWSPluginsCore

import AWSS3
import XCTest

final class AWSS3StorageUploadFileOperationTests2: AWSS3StorageOperationTestBase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// - Given: A file with no read permissions from the user
    /// - When: An attempt is made to upload it
    /// - Then: An accessDenied error is returned before attempting proceed further
    func testAccessDenied() throws {
        let path = NSTemporaryDirectory().appending(UUID().uuidString)
        FileManager.default.createFile(atPath: path,
                                       contents: Data(UUID().uuidString.utf8),
                                       attributes: [FileAttributeKey.posixPermissions: 000])
        defer {
            try? FileManager.default.removeItem(atPath: path)
        }

        let url = URL(fileURLWithPath: path)
        let key = (path as NSString).lastPathComponent
        let options = StorageUploadFileRequest.Options(accessLevel: .protected)
        let request = StorageUploadFileRequest(key: key, local: url, options: options)

        let progressExpectation = expectation(description: "progress")
        progressExpectation.isInverted = true
        let progressListner: ProgressListener = { _ in progressExpectation.fulfill() }

        let resultExpectation = expectation(description: "result")
        let resultListener: StorageUploadFileOperation.ResultListener = { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .failure(let error):
                guard case .accessDenied(let description, let recommendation, _) = error else {
                    XCTFail("Should have failed with validation error")
                    return
                }
                XCTAssertEqual(description, "Access to local file denied: \(path)")
                XCTAssertEqual(recommendation, "Please ensure that \(url) is readable")
            case .success:
                XCTFail("Expecting an error but got success")
            }
        }

        let operation = AWSS3StorageUploadFileOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: progressListner,
                                                        resultListener: resultListener)
        operation.start()

        wait(for: [progressExpectation, resultExpectation], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }
}
