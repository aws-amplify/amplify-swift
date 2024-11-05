//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import class AWSClientRuntime.AWSClientConfigDefaultsProvider
import protocol ClientRuntime.ClientConfiguration
import protocol ClientRuntime.Plugin
import protocol SmithyHTTPAuthAPI.AuthSchemeResolver
import protocol SmithyIdentity.AWSCredentialIdentityResolver
import protocol SmithyIdentity.BearerTokenIdentityResolver
import struct AWSSDKHTTPAuth.SigV4AuthScheme
import struct SmithyIdentity.BearerTokenIdentity
import struct SmithyIdentity.StaticBearerTokenIdentityResolver
import typealias SmithyHTTPAuthAPI.AuthSchemes

public class SageMakerGeospatialClientEndpointPlugin: Plugin {
    private var endpointResolver: EndpointResolver

    public init(endpointResolver: EndpointResolver) {
        self.endpointResolver = endpointResolver
    }

    public convenience init() throws {
        self.init(endpointResolver: try DefaultEndpointResolver())
    }

    public func configureClient(clientConfiguration: ClientRuntime.ClientConfiguration) throws {
        if let config = clientConfiguration as? SageMakerGeospatialClient.SageMakerGeospatialClientConfiguration {
            config.endpointResolver = self.endpointResolver
        }
    }
}

public class DefaultAWSAuthSchemePlugin: ClientRuntime.Plugin {

    public init() {}

    public func configureClient(clientConfiguration: ClientRuntime.ClientConfiguration) throws {
        if let config = clientConfiguration as? SageMakerGeospatialClient.SageMakerGeospatialClientConfiguration {
            config.authSchemeResolver = DefaultSageMakerGeospatialAuthSchemeResolver()
            config.authSchemes = [AWSSDKHTTPAuth.SigV4AuthScheme()]
            config.awsCredentialIdentityResolver = try AWSClientRuntime.AWSClientConfigDefaultsProvider.awsCredentialIdentityResolver()
            config.bearerTokenIdentityResolver = SmithyIdentity.StaticBearerTokenIdentityResolver(token: SmithyIdentity.BearerTokenIdentity(token: ""))
        }
    }
}

public class SageMakerGeospatialClientAuthSchemePlugin: ClientRuntime.Plugin {
    private var authSchemes: SmithyHTTPAuthAPI.AuthSchemes?
    private var authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver?
    private var awsCredentialIdentityResolver: (any SmithyIdentity.AWSCredentialIdentityResolver)?
    private var bearerTokenIdentityResolver: (any SmithyIdentity.BearerTokenIdentityResolver)?

    public init(authSchemes: SmithyHTTPAuthAPI.AuthSchemes? = nil, authSchemeResolver: SageMakerGeospatialAuthSchemeResolver? = nil, awsCredentialIdentityResolver: (any SmithyIdentity.AWSCredentialIdentityResolver)? = nil, bearerTokenIdentityResolver: (any SmithyIdentity.BearerTokenIdentityResolver)? = nil) {
        self.authSchemeResolver = authSchemeResolver
        self.authSchemes = authSchemes
        self.awsCredentialIdentityResolver = awsCredentialIdentityResolver
        self.bearerTokenIdentityResolver = bearerTokenIdentityResolver
    }

    public func configureClient(clientConfiguration: ClientRuntime.ClientConfiguration) throws {
        if let config = clientConfiguration as? SageMakerGeospatialClient.SageMakerGeospatialClientConfiguration {
            if (self.authSchemes != nil) {
                config.authSchemes = self.authSchemes
            }
            if (self.authSchemeResolver != nil) {
                config.authSchemeResolver = self.authSchemeResolver!
            }
            if (self.awsCredentialIdentityResolver != nil) {
                config.awsCredentialIdentityResolver = self.awsCredentialIdentityResolver!
            }
            if (self.bearerTokenIdentityResolver != nil) {
                config.bearerTokenIdentityResolver = self.bearerTokenIdentityResolver!
            }
        }
    }
}