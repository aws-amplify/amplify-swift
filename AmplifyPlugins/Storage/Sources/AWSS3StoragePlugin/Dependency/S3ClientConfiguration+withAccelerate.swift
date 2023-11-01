//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
//import AWSS3

// TODO: This can be removed now that our ClientConfiguration has value semantics
extension S3ClientConfiguration {
    func withAccelerate(_ shouldAccelerate: Bool?) throws -> S3ClientConfiguration {
        // if `shouldAccelerate` is `nil`, this is a noop - return self
        guard let shouldAccelerate else {
            return self
        }

        // if `shouldAccelerate` isn't `nil` and
        // is equal to the exisiting config's `serviceSpecific.accelerate
        // we can avoid allocating a new configuration object.
        if shouldAccelerate == accelerate {
            return self
        }

        return .init(
            region: region,
            credentialsProvider: credentialsProvider,
            accelerate: shouldAccelerate,
            encoder: JSONEncoder(),
            decoder: JSONDecoder()
        )
    }
}
