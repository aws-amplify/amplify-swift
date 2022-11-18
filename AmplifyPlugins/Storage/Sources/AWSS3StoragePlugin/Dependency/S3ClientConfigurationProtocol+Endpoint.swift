// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSS3

extension S3ClientConfigurationProtocol {

    func endpointParams(withBucket bucket: String?) -> EndpointParams {
        EndpointParams(
            accelerate: accelerate ?? false,
            bucket: bucket,
            disableMultiRegionAccessPoints: disableMultiRegionAccessPoints ?? false,
            endpoint: endpoint,
            forcePathStyle: forcePathStyle,
            region: region,
            useArnRegion: useArnRegion,
            useDualStack: useDualStack ?? false,
            useFIPS: useFIPS ?? false,
            useGlobalEndpoint: useGlobalEndpoint ?? false)
    }

}
