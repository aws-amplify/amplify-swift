//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
import Foundation
@testable import AWSS3StoragePlugin
import AWSS3

public class MockAWSS3TransferUtility: AWSS3TransferUtilityBehavior {

    public var errorOnContinuation: NSError?
    public var errorOnCompletion: NSError?

    private(set) public var downloadDataCalled = 0
    private(set) public var downloadToURLCalled = 0
    private(set) public var uploadDataCalled = 0
    private(set) public var uploadFileCalled = 0
    private(set) public var multiPartUploadFileCalled = 0
    private(set) public var multiPartUploadDataCalled = 0

    public func downloadData(fromBucket: String,
                             key: String,
                             expression: AWSS3TransferUtilityDownloadExpression,
                             completionHandler: (AWSS3TransferUtilityDownloadCompletionHandlerBlock)?)
    -> AWSTask<AWSS3TransferUtilityDownloadTask> {

        downloadDataCalled += 1

        if let error = errorOnContinuation {
            let resultWithError = AWSTask<AWSS3TransferUtilityDownloadTask>.init(error: error)
            return resultWithError
        }

        let task = MockTransferUtilityDownloadTask()

        let url = URL(fileURLWithPath: "path")
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        task.response = response

        if let progressBlock = expression.progressBlock {
            progressBlock(task, Progress())
        }

        if let completionHandler = completionHandler {
            if let error = errorOnCompletion {
                completionHandler(task, nil, nil, error)
            } else {
                completionHandler(task, nil, Data(), nil)
            }
        }

        let result = AWSTask<AWSS3TransferUtilityDownloadTask>.init(result: task)
        return result
    }

    public func download(to fileURL: URL,
                         bucket: String,
                         key: String,
                         expression: AWSS3TransferUtilityDownloadExpression,
                         completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?)
    -> AWSTask<AWSS3TransferUtilityDownloadTask> {

        downloadToURLCalled += 1

        if let error = errorOnContinuation {
            let resultWithError = AWSTask<AWSS3TransferUtilityDownloadTask>.init(error: error)
            return resultWithError
        }

        let task = AWSS3TransferUtilityDownloadTask()

        if let progressBlock = expression.progressBlock {
            progressBlock(task, Progress())
        }

        if let completionHandler = completionHandler {
            if let error = errorOnCompletion {
                completionHandler(task, nil, nil, error)
            } else {
                completionHandler(task, nil, Data(), nil)
            }
        }

        let result = AWSTask<AWSS3TransferUtilityDownloadTask>.init(result: task)
        return result
    }

    // swiftlint:disable function_parameter_count
    public func uploadData(data: Data,
                           bucket: String,
                           key: String,
                           contentType: String,
                           expression: AWSS3TransferUtilityUploadExpression,
                           completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?)
    -> AWSTask<AWSS3TransferUtilityUploadTask> {

        uploadDataCalled += 1

        if let error = errorOnContinuation {
            let resultWithError = AWSTask<AWSS3TransferUtilityUploadTask>.init(error: error)
            return resultWithError
        }

        let task = AWSS3TransferUtilityUploadTask()

        if let progressBlock = expression.progressBlock {
            progressBlock(task, Progress())
        }

        if let completionHandler = completionHandler {
            if let error = errorOnCompletion {
                completionHandler(task, error)
            } else {
                completionHandler(task, nil)
            }
        }

        let result = AWSTask<AWSS3TransferUtilityUploadTask>.init(result: task)
        return result
    }

    public func uploadFile(fileURL: URL,
                           bucket: String,
                           key: String,
                           contentType: String,
                           expression: AWSS3TransferUtilityUploadExpression,
                           completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?)
    -> AWSTask<AWSS3TransferUtilityUploadTask> {
        uploadFileCalled += 1

        if let error = errorOnContinuation {
            let resultWithError = AWSTask<AWSS3TransferUtilityUploadTask>.init(error: error)
            return resultWithError
        }

        let task = AWSS3TransferUtilityUploadTask()

        if let progressBlock = expression.progressBlock {
            progressBlock(task, Progress())
        }

        if let completionHandler = completionHandler {
            if let error = errorOnCompletion {
                completionHandler(task, error)
            } else {
                completionHandler(task, nil)
            }
        }

        let result = AWSTask<AWSS3TransferUtilityUploadTask>.init(result: task)
        return result

    }

    public func uploadUsingMultiPart(fileURL: URL,
                                     bucket: String,
                                     key: String,
                                     contentType: String,
                                     expression: AWSS3TransferUtilityMultiPartUploadExpression,
                                     completionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityMultiPartUploadTask> {

        multiPartUploadFileCalled += 1

        if let error = errorOnContinuation {
            let resultWithError = AWSTask<AWSS3TransferUtilityMultiPartUploadTask>.init(error: error)
            return resultWithError
        }

        let task = AWSS3TransferUtilityMultiPartUploadTask()

        if let progressBlock = expression.progressBlock {
            progressBlock(task, Progress())
        }

        if let completionHandler = completionHandler {
            if let error = errorOnCompletion {
                completionHandler(task, error)
            } else {
                completionHandler(task, nil)
            }
        }

        let result = AWSTask<AWSS3TransferUtilityMultiPartUploadTask>.init(result: task)
        return result
    }

    public func uploadUsingMultiPart(data: Data,
                                     bucket: String,
                                     key: String,
                                     contentType: String,
                                     expression: AWSS3TransferUtilityMultiPartUploadExpression,
                                     completionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityMultiPartUploadTask> {

        multiPartUploadDataCalled += 1

        if let error = errorOnContinuation {
            let resultWithError = AWSTask<AWSS3TransferUtilityMultiPartUploadTask>.init(error: error)
            return resultWithError
        }

        let task = AWSS3TransferUtilityMultiPartUploadTask()

        if let progressBlock = expression.progressBlock {
            progressBlock(task, Progress())
        }

        if let completionHandler = completionHandler {
            if let error = errorOnCompletion {
                completionHandler(task, error)
            } else {
                completionHandler(task, nil)
            }
        }

        let result = AWSTask<AWSS3TransferUtilityMultiPartUploadTask>.init(result: task)
        return result
    }
}

class MockTransferUtilityDownloadTask: AWSS3TransferUtilityDownloadTask {

    var mockResponse: HTTPURLResponse?

    override var response: HTTPURLResponse? {

        get {
            return mockResponse
        }

        set {
            mockResponse = newValue
        }
    }
}
*/
