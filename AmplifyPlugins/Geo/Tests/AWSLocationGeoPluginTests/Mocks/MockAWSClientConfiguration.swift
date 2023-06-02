//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import ClientRuntime
import AWSLocation
import Foundation
import XCTest

@testable import AWSLocationGeoPlugin
@testable import AWSPluginsTestCommon

class MockAWSClientConfiguration: LocationClientConfigurationProtocol {
    var encoder: ClientRuntime.RequestEncoder?
    
    var decoder: ClientRuntime.ResponseDecoder?
    
    var httpClientEngine: ClientRuntime.HttpClientEngine
    
    var httpClientConfiguration: ClientRuntime.HttpClientConfiguration
    
    var idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator
    
    var clientLogMode: ClientRuntime.ClientLogMode
    
    var partitionID: String?
    
    var useFIPS: Bool?

    var useDualStack: Bool?

    var endpoint: String?

    var credentialsProvider: CredentialsProviding

    var region: String?

    var signingRegion: String?

    var endpointResolver: EndpointResolver

    var regionResolver: RegionResolver?

    var frameworkMetadata: FrameworkMetadata?

    var logger: LogAgent

    var retryer: SDKRetryer

    init(config: AWSLocationGeoPluginConfiguration) throws {
        let defaultSDKRuntimeConfig = try DefaultSDKRuntimeConfiguration("MockAWSClientConfiguration")
        
        self.httpClientEngine = defaultSDKRuntimeConfig.httpClientEngine
        self.httpClientConfiguration = defaultSDKRuntimeConfig.httpClientConfiguration
        self.idempotencyTokenGenerator = defaultSDKRuntimeConfig.idempotencyTokenGenerator
        self.clientLogMode = defaultSDKRuntimeConfig.clientLogMode
        self.credentialsProvider = MockAWSAuthService().getCredentialsProvider()
        self.region = config.regionName
        self.signingRegion = ""
        self.endpointResolver = MockEndPointResolver()
        self.logger = MockLogAgent()
        self.retryer = try SDKRetryer(options: RetryOptions(jitterMode: .default))
    }
}

class MockEndPointResolver: EndpointResolver {
    func resolve(params: AWSLocation.EndpointParams) throws -> ClientRuntime.Endpoint {
        return Endpoint(host: "MockHost")
    }
}

class MockLogAgent: LogAgent {
    var name: String = ""

    var level: LogAgentLevel = .debug

    func log(level: LogAgentLevel, message: String, metadata: [String: String]?, source: String, file: String, function: String, line: UInt) {
        print("MockLogAgent")
    }
}
