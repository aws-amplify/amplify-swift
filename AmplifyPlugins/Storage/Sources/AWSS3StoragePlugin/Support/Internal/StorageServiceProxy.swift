//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// - Note: `Sendable` because the multipart upload client captures the proxy in the tasks it uses
///   to upload parts.
protocol StorageServiceProxy: AnyObject, Sendable {
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior! { get }
    var awsS3: AWSS3Behavior! { get }
    var urlSession: URLSession { get }
    var userAgent: String { get async }
    var urlRequestDelegate: URLRequestDelegate? { get }

    func register(task: StorageTransferTask)
    func unregister(task: StorageTransferTask)
    func unregister(taskIdentifiers: [TaskIdentifier])

    func register(multipartUploadSession: StorageMultipartUploadSession)
    func unregister(multipartUploadSession: StorageMultipartUploadSession)
}
