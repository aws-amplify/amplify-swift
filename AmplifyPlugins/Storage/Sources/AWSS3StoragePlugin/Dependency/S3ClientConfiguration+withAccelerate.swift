//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

extension S3Client.S3ClientConfiguration {
    func withAccelerate(_ shouldAccelerate: Bool?) throws -> S3Client.S3ClientConfiguration {
        // if `shouldAccelerate` is `nil`, this is a noop - return self
        guard let shouldAccelerate else {
            return self
        }

        // if `shouldAccelerate` isn't `nil` and
        // is equal to the exisiting config's `serviceSpecific.accelerate
        // we can avoid allocating a new configuration object.
        if shouldAccelerate == serviceSpecific.accelerate {
            return self
        }

        // This shouldn't happen based on how we're initially
        // creating the configuration, but we can't reasonably prove
        // it at compile time - so we have to unwrap.
        guard let region else { return self }

        // `S3Client.ServiceSpecificConfiguration` is a struct
        // so we're copying by value here.
        var serviceSpecific = serviceSpecific
        serviceSpecific.accelerate = shouldAccelerate

        // `S3Client.S3ClientConfiguration` is a `class` so we need to make
        // a deep copy here as not to change the value of the existing base
        // configuration.
        let copy = try S3Client.S3ClientConfiguration(
            region: region,
            credentialsProvider: credentialsProvider,
            endpoint: endpoint,
            serviceSpecific: serviceSpecific,
            signingRegion: signingRegion,
            useDualStack: useDualStack,
            useFIPS: useFIPS,
            retryMode: awsRetryMode,
            appID: appID,
            connectTimeoutMs: connectTimeoutMs
        )

        return copy
    }
}
