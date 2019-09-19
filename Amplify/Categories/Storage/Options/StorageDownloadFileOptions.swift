//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StorageDownloadFileOptions {

    public var accessLevel: StorageAccessLevel?

    public let targetIdentityId: String?

    public var options: Any?

    // TODO: transferAcceleration should be in options most likely. and can be set globally
    // https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html

    public init(accessLevel: StorageAccessLevel? = nil,
                targetIdentityId: String? = nil,
                options: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.options = options
    }
}
