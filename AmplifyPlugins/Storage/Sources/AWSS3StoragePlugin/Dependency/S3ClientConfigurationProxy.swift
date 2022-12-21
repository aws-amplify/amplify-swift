// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import AWSS3
import AWSClientRuntime
import ClientRuntime
import Foundation

/// Convenience proxy class around a
/// [S3ClientConfigurationProtocol](x-source-tag://S3ClientConfigurationProtocol)
/// implementaitons that allows Amplify to change configuration values JIT.
///
/// - Tag: S3ClientConfigurationProxy
struct S3ClientConfigurationProxy {

    /// - Tag: S3ClientConfigurationProxy.target
    var target: S3ClientConfigurationProtocol

    /// - Tag: S3ClientConfigurationProxy.accelerateOverride
    var accelerateOverride: Bool?
}

extension S3ClientConfigurationProxy: S3ClientConfigurationProtocol {
    
    var accelerate: Bool? {
        if let accelerateOverride = accelerateOverride {
            return accelerateOverride
        }
        return target.accelerate
    }
    
    var disableMultiRegionAccessPoints: Bool? {
        return target.disableMultiRegionAccessPoints
    }
    
    var endpointResolver: EndpointResolver {
        return target.endpointResolver
    }
    
    var forcePathStyle: Bool? {
        return target.forcePathStyle
    }
    
    var useArnRegion: Bool? {
        return target.useArnRegion
    }
    
    var useGlobalEndpoint: Bool? {
        return target.useGlobalEndpoint
    }
    
    var credentialsProvider: AWSClientRuntime.CredentialsProvider {
        get {
            return target.credentialsProvider
        }
        set(newValue) {
            target.credentialsProvider = newValue
        }
    }
    
    var region: String? {
        get {
            return target.region
        }
        set(newValue) {
            target.region = newValue
        }
    }
    
    var signingRegion: String? {
        get {
            return target.signingRegion
        }
        set(newValue) {
            target.signingRegion = newValue
        }
    }
    
    var regionResolver: RegionResolver? {
        get {
            return target.regionResolver
        }
        set(newValue) {
            target.regionResolver = newValue
        }
    }
    
    var frameworkMetadata: FrameworkMetadata? {
        get {
            return target.frameworkMetadata
        }
        set(newValue) {
            target.frameworkMetadata = newValue
        }
    }
    
    var useFIPS: Bool? {
        get {
            return target.useFIPS
        }
        set(newValue) {
            target.useFIPS = newValue
        }
    }
    
    var useDualStack: Bool? {
        get {
            return target.useDualStack
        }
        set(newValue) {
            target.useDualStack = newValue
        }
    }
    
    var logger: LogAgent {
        return target.logger
    }
    
    var retryer: ClientRuntime.SDKRetryer {
        return target.retryer
    }
    
    var endpoint: String? {
        get {
            return target.endpoint
        }
        set(newValue) {
            target.endpoint = newValue
        }
    }
}
