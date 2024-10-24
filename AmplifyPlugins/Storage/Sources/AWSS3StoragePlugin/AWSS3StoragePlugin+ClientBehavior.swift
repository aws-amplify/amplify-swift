//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import AWSPluginsCore
import AWSS3

public extension AWSS3StoragePlugin {

    /// Retrieve the escape hatch to perform low level operations on S3.
    ///
    /// - Returns: S3 client
    ///
    /// - Tag: AWSS3StoragePlugin.getEscapeHatch
    func getEscapeHatch() -> S3Client {
        return defaultStorageService.getEscapeHatch()
    }
}
