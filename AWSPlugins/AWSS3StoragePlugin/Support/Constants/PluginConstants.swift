//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
struct PluginConstants {
    static let awsS3StoragePluginKey = "AWSS3StoragePlugin"
    static let bucket = "Bucket"
    static let region = "Region"
    static let defaultAccessLevel = "DefaultAccessLevel"
    static let multiPartUploadSizeThreshold = 10_000_000 // 10MB
    static let defaultURLExpireTime = 18_000 // in seconds
}
