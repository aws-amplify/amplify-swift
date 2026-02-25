//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AwsCommonRuntimeKit
import Foundation
import Smithy
import SmithyIdentity

/**
 Converts CRT credentials provider to AWSCredentialsProvider
 */
public extension AWSCredentialsProvider where Self: AwsCommonRuntimeKit.CredentialsProviding {
    func resolve() async throws -> AWSCredentials {
        return try await getCredentials().toAWSCredentials()
    }
}

/**
 Converts Smithy credentials provider AWSCredentialsProvider 
 */
public extension AWSCredentialsProvider where Self: AWSCredentialIdentityResolver {
    func resolve() async throws -> AWSCredentials {
        return try await getIdentity(identityProperties: nil).toAWSCredentials()
    }
}

/**
 Converts AWSCredentialsProvider to CRT credentials provider
 */
public extension AwsCommonRuntimeKit.CredentialsProviding where Self: AWSCredentialsProvider {
    func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        let credentials = try await resolve()
        return try credentials.toAWSSDKCredentials()
    }
}

/**
 Converts AWSCredentialsProvider to Smithy credentials provider
 */
public extension AWSCredentialIdentityResolver where Self: AWSCredentialsProvider {
    func getIdentity(identityProperties: Smithy.Attributes? = nil) async throws -> AWSCredentialIdentity {
        let credentials = try await resolve()
        return try credentials.toAWSCredentialIdentity()
    }
}

/**
 Adapter that wraps a Foundation AWSCredentialsProvider to work as an SDK AWSCredentialIdentityResolver.
 */
public struct FoundationToSDKCredentialsAdapter: AWSCredentialsProvider, AWSCredentialIdentityResolver, @unchecked Sendable {
    private let provider: any AWSCredentialsProvider
    
    public init(provider: any AWSCredentialsProvider) {
        self.provider = provider
    }
    
    public func resolve() async throws -> AWSCredentials {
        return try await provider.resolve()
    }
    
    // getIdentity() is automatically provided by the bridge extension:
    // extension AWSCredentialIdentityResolver where Self: AWSCredentialsProvider
}

/**
 Adapter that wraps an SDK AWSCredentialIdentityResolver to work as a Foundation AWSCredentialsProvider.
 */
public struct SDKToFoundationCredentialsAdapter: AWSCredentialIdentityResolver, AWSCredentialsProvider, @unchecked Sendable {
    private let resolver: any AWSCredentialIdentityResolver
    
    public init(resolver: any AWSCredentialIdentityResolver) {
        self.resolver = resolver
    }
    
    public func getIdentity(identityProperties: Smithy.Attributes? = nil) async throws -> AWSCredentialIdentity {
        return try await resolver.getIdentity(identityProperties: identityProperties)
    }
    
    // resolve() is automatically provided by the bridge extension:
    // extension AWSCredentialsProvider where Self: AWSCredentialIdentityResolver
}

/**
 Adapter that wraps a Foundation AWSCredentialsProvider to work as a CRT CredentialsProviding.
 */
public struct FoundationToCRTCredentialsAdapter: AWSCredentialsProvider, AwsCommonRuntimeKit.CredentialsProviding, @unchecked Sendable {
    private let provider: any AWSCredentialsProvider
    
    public init(provider: any AWSCredentialsProvider) {
        self.provider = provider
    }
    
    public func resolve() async throws -> AWSCredentials {
        return try await provider.resolve()
    }
    
    // getCredentials() is automatically provided by the bridge extension:
    // extension AWSCredentialIdentityResolver where Self: AWSCredentialsProvider
}

/**
 Adapter that wraps a CRT CredentialsProviding to work as a Foundation AWSCredentialsProvider.
 */
public struct CRTToFoundationCredentialsAdapter: AwsCommonRuntimeKit.CredentialsProviding, AWSCredentialsProvider, @unchecked Sendable {
    private let provider: any AwsCommonRuntimeKit.CredentialsProviding
    
    public init(provider: any AwsCommonRuntimeKit.CredentialsProviding) {
        self.provider = provider
    }
    
    public func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        return try await provider.getCredentials()
    }
    
    // resolve() is automatically provided by the bridge extension:
    // extension AWSCredentialsProvider where Self: AwsCommonRuntimeKit.CredentialsProviding
}
