// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSS3

extension S3Client.S3ClientConfiguration {
    func endpointParams(withBucket bucket: String?) -> EndpointParams {
        EndpointParams(
            accelerate: serviceSpecific.accelerate ?? false,
            bucket: bucket,
            disableMultiRegionAccessPoints: serviceSpecific.disableMultiRegionAccessPoints ?? false,
            endpoint: endpoint,
            forcePathStyle: serviceSpecific.forcePathStyle ?? false,
            region: region,
            useArnRegion: serviceSpecific.useArnRegion,
            useDualStack: useDualStack ?? false,
            useFIPS: useFIPS ?? false,
            useGlobalEndpoint: serviceSpecific.useGlobalEndpoint ?? false
        )
    }

}
