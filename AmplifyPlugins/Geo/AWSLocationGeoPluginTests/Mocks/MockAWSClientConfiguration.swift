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

class MockAWSClientConfiguration: AWSClientRuntime.AWSClientConfiguration {
    var credentialsProvider: CredentialsProvider

    var region: String?

    var signingRegion: String?

    var endpointResolver: EndpointResolver

    var regionResolver: RegionResolver?

    var frameworkMetadata: FrameworkMetadata?

    var logger: LogAgent

    var retryer: SDKRetryer

    init(config: AWSLocationGeoPluginConfiguration) throws {
        self.credentialsProvider = MockAWSAuthService().getCredentialsProvider()
        self.region = config.regionName
        self.signingRegion = ""
        self.endpointResolver = MockEndPointResolver()
        self.logger = MockLogAgent()
        self.retryer = try SDKRetryer(options: RetryOptions(backOffRetryOptions: ExponentialBackOffRetryOptions()))
    }
}

class MockEndPointResolver: EndpointResolver {
    func resolve(serviceId: String, region: String) throws -> AWSEndpoint {
        return AWSEndpoint(endpoint: Endpoint(host: "MockHost"))
    }
}

class MockLogAgent: LogAgent {
    var name: String = ""

    var level: LogAgentLevel = .debug

    func log(level: LogAgentLevel, message: String, metadata: [String: String]?, source: String, file: String, function: String, line: UInt) {
        print("MockLogAgent")
    }
}
