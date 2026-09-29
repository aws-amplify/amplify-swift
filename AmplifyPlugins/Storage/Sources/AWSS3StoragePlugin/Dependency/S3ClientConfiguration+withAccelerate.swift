//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import Foundation

extension S3Client.S3ClientConfig {
    func withAccelerate(_ shouldAccelerate: Bool?) throws -> S3Client.S3ClientConfig {
        // if `shouldAccelerate` is `nil` or equal to the existing config's
        // `accelerate`, this is a noop - return self
        guard let shouldAccelerate, shouldAccelerate != accelerate else {
            return self
        }

        var copy = self
        copy.accelerate = shouldAccelerate
        return copy
    }
}
