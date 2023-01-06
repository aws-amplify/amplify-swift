//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin
@testable import AWSPluginsCore
import AWSS3

final class AWSS3StorageUploadFileOperationTests2: AWSS3StorageOperationTestBase {

    func testUploadFileOperationAccessDenied() throws {
        let url = try createInaccessibleFile(with: Data(UUID().uuidString.utf8))
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let key = (url.path as NSString).lastPathComponent
        let options = StorageUploadFileRequest.Options(accessLevel: .protected)
        let request = StorageUploadFileRequest(key: key, local: url, options: options)

        let progressExpectation = expectation(description: "progress")
        progressExpectation.isInverted = true
        let progressListner: ProgressListener = { _ in progressExpectation.fulfill() }

        let resultExpectation = expectation(description: "result")
        let resultListener: StorageUploadFileOperation.ResultListener = { result in
            switch result {
            case .failure(let error):
                guard case .accessDenied = error else {
                    XCTFail("Should have failed with validation error")
                    return
                }
                resultExpectation.fulfill()
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

    private func createInaccessibleFile(with contents: Data) throws -> URL {
        let url = try createTemporaryFile(with: Data(UUID().uuidString.utf8))
        try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: 000], ofItemAtPath: url.path)
        return url
    }

    private func createTemporaryFile(with contents: Data) throws -> URL {
        let path = NSTemporaryDirectory().appending(UUID().uuidString)
        FileManager.default.createFile(atPath: path, contents: contents)
        return URL(fileURLWithPath: path)
    }

}
