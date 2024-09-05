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
        // is equal to the exisiting config's `accelerate`
        // we can avoid allocating a new configuration object.
        if shouldAccelerate == accelerate {
            return self
        }

        // `S3Client.S3ClientConfiguration` is a `class` so we need to make
        // a deep copy here as not to change the value of the existing base
        // configuration.
        let copy =  try S3Client.S3ClientConfiguration(
            useFIPS: useFIPS,
            useDualStack: useDualStack,
            appID: appID,
            awsCredentialIdentityResolver: awsCredentialIdentityResolver,
            awsRetryMode: awsRetryMode,
            region: region,
            signingRegion: signingRegion,
            forcePathStyle: forcePathStyle,
            useArnRegion: useArnRegion,
            disableMultiRegionAccessPoints: disableMultiRegionAccessPoints,
            accelerate: shouldAccelerate,
            disableS3ExpressSessionAuth: disableS3ExpressSessionAuth,
            useGlobalEndpoint: useGlobalEndpoint,
            endpointResolver: endpointResolver,
            telemetryProvider: telemetryProvider,
            retryStrategyOptions: retryStrategyOptions,
            clientLogMode: clientLogMode,
            endpoint: endpoint,
            idempotencyTokenGenerator: idempotencyTokenGenerator,
            httpClientEngine: httpClientEngine,
            httpClientConfiguration: httpClientConfiguration,
            authSchemes: authSchemes,
            authSchemeResolver: authSchemeResolver,
            bearerTokenIdentityResolver: bearerTokenIdentityResolver,
            interceptorProviders: interceptorProviders,
            httpInterceptorProviders: httpInterceptorProviders
        )

        return copy
    }
}
