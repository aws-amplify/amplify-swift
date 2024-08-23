//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
@_spi(InternalAmplifyConfiguration) @testable import Amplify

final class AWSAppSyncConfigurationTests: XCTestCase {

    func testSuccess() throws {
        let config = AmplifyOutputsData(data: .init(
            awsRegion: "us-east-1",
            url: "http://www.example.com",
            modelIntrospection: nil,
            apiKey: "apiKey123",
            defaultAuthorizationType: .amazonCognitoUserPools,
            authorizationTypes: [.apiKey, .awsIAM]))
        let encoder = JSONEncoder()
        let data = try! encoder.encode(config)

        let configuration = try AWSAppSyncConfiguration(with: .data(data))

        XCTAssertEqual(configuration.region, "us-east-1")
        XCTAssertEqual(configuration.endpoint, URL(string: "http://www.example.com")!)
        XCTAssertEqual(configuration.apiKey, "apiKey123")
    }
}
