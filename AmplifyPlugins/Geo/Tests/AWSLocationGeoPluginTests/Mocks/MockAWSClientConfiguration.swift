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
import SmithyHTTPAPI
import Smithy

@testable import AWSLocationGeoPlugin
@testable import AWSPluginsTestCommon

extension LocationClient.LocationClientConfiguration {
    static func mock(region: String) throws -> LocationClient.LocationClientConfiguration {
        try .init(
            awsCredentialIdentityResolver: MockAWSAuthService().getCredentialIdentityResolver(),
            awsRetryMode: .standard, 
            region: region,
            signingRegion: "", 
            endpointResolver: MockEndPointResolver()
        )
    }
}

class MockEndPointResolver: EndpointResolver {
    func resolve(params: AWSLocation.EndpointParams) throws -> SmithyHTTPAPI.Endpoint {
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
