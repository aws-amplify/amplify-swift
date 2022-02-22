//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol StorageServiceProxy: AnyObject {
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior! { get }
    var awsS3: AWSS3Behavior! { get }
    var urlSession: URLSession { get }

    func register(task: StorageTransferTask)
    func unregister(task: StorageTransferTask)
}
