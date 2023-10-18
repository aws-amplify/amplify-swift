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

extension LocationClient.LocationClientConfiguration {
    static func mock(region: String) throws -> LocationClient.LocationClientConfiguration {
        try .init(
            region: region,
            credentialsProvider: MockAWSAuthService().getCredentialsProvider(),
            serviceSpecific: .init(
                endpointResolver: MockEndPointResolver()
            ),
            signingRegion: "",
            retryMode: .standard
        )
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
