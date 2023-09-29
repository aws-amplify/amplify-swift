// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import AWSS3
import AWSClientRuntime
import ClientRuntime
import Foundation

extension S3Client.S3ClientConfiguration {
    func accelerate(_ shouldAccelerate: Bool?) -> S3Client.S3ClientConfiguration {
        self.serviceSpecific.accelerate = shouldAccelerate
        return self
    }
}
