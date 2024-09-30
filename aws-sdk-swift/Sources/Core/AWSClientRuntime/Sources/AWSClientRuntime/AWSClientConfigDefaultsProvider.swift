//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(FileBasedConfig) import AWSSDKCommon
@_spi(DefaultAWSCredentialIdentityResolverChain) import AWSSDKIdentity
import SmithyIdentity
import SmithyIdentityAPI
import struct ClientRuntime.DefaultSDKRuntimeConfiguration
import enum ClientRuntime.DefaultRetryErrorInfoProvider
import protocol SmithyHTTPAPI.HTTPClient
import class ClientRuntime.HttpClientConfiguration
import protocol ClientRuntime.IdempotencyTokenGenerator
import enum ClientRuntime.ClientLogMode
import struct SmithyRetries.DefaultRetryStrategy
import struct SmithyRetries.ExponentialBackoffStrategy
import struct SmithyRetriesAPI.RetryStrategyOptions

typealias RuntimeConfigType = DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>

/// Provides default configuration properties for AWS services.
public class AWSClientConfigDefaultsProvider {
    public static func httpClientEngine() -> HTTPClient {
        return RuntimeConfigType.makeClient(
            httpClientConfiguration: RuntimeConfigType.defaultHttpClientConfiguration
        )
    }

    public static func httpClientConfiguration() -> HttpClientConfiguration {
        return RuntimeConfigType.defaultHttpClientConfiguration
    }

    public static func idempotencyTokenGenerator() -> IdempotencyTokenGenerator {
        return RuntimeConfigType.defaultIdempotencyTokenGenerator
    }

    public static func clientLogMode() -> ClientLogMode {
        return RuntimeConfigType.defaultClientLogMode
    }

    public static func awsCredentialIdentityResolver(
        _ awsCredentialIdentityResolver: (any AWSCredentialIdentityResolver)? = nil
    ) throws -> any AWSCredentialIdentityResolver {
        let resolvedAWSCredentialIdentityResolver: any AWSCredentialIdentityResolver
        let fileBasedConfig = try CRTFileBasedConfiguration.make()
        if let awsCredentialIdentityResolver {
            resolvedAWSCredentialIdentityResolver = awsCredentialIdentityResolver
        } else {
            resolvedAWSCredentialIdentityResolver = try DefaultAWSCredentialIdentityResolverChain(
                fileBasedConfig: fileBasedConfig
            )
        }
        return resolvedAWSCredentialIdentityResolver
    }

    public static func region(_ region: String? = nil) async throws -> String? {
        let resolvedRegion: String?
        let fileBasedConfig = try await CRTFileBasedConfiguration.makeAsync()
        if let region = region {
            resolvedRegion = region
        } else {
            let regionResolver = try DefaultRegionResolver { _, _ in fileBasedConfig }
            resolvedRegion = await regionResolver.getRegion()
        }

        return resolvedRegion
    }

    public static func appID(_ appID: String? = nil) throws -> String? {
        let fileBasedConfig = try CRTFileBasedConfiguration.make()
        let resolvedAppID: String?
        if let appID = appID {
            resolvedAppID = appID
        } else {
            resolvedAppID = AppIDConfig.appID(
                configValue: nil,
                profileName: nil,
                fileBasedConfig: fileBasedConfig
            )
        }
        return resolvedAppID
    }

    public static func retryMode(_ retryMode: AWSRetryMode? = nil) throws -> AWSRetryMode {
        let fileBasedConfig = try CRTFileBasedConfiguration.make()
        let resolvedRetryMode: AWSRetryMode?
        if let retryMode = retryMode {
            resolvedRetryMode = retryMode
        } else {
            resolvedRetryMode = AWSRetryConfig.retryMode(
                configValue: nil,
                profileName: nil,
                fileBasedConfig: fileBasedConfig
            )
        }
        return resolvedRetryMode!
    }

    private static func maxAttempts(_ maxAttempts: Int? = nil) throws -> Int {
        let fileBasedConfig = try CRTFileBasedConfiguration.make()
        let resolvedMaxAttempts: Int?
        if let maxAttempts {
            resolvedMaxAttempts = maxAttempts
        } else {
            resolvedMaxAttempts = AWSRetryConfig.maxAttempts(
                configValue: nil,
                profileName: nil,
                fileBasedConfig: fileBasedConfig
            )
        }
        return resolvedMaxAttempts!
    }

    public static func retryStrategyOptions(
        _ retryMode: AWSRetryMode? = nil,
        _ maxAttempts: Int? = nil
    ) throws -> RetryStrategyOptions {
        let resolvedMaxAttempts = try self.maxAttempts(maxAttempts)

        let resolvedRateLimitingMode: RetryStrategyOptions.RateLimitingMode

        switch try self.retryMode(retryMode) {
        case .legacy, .standard:
            resolvedRateLimitingMode = .standard
        case .adaptive:
            resolvedRateLimitingMode = .adaptive
        }

        return RetryStrategyOptions(
            backoffStrategy: ExponentialBackoffStrategy(),
            maxRetriesBase: resolvedMaxAttempts - 1,
            rateLimitingMode: resolvedRateLimitingMode
        )
    }
}
