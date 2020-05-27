//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPICategoryPlugin
import AWSPluginsCore

// swiftlint:disable:next type_name
class AWSAPICategoryPluginInterceptorBehaviorTests: AWSAPICategoryPluginTestBase {

    // TODO: Fix test failure
    func testAddInterceptor() throws {
        XCTAssertNotNil(apiPlugin.pluginConfig.endpoints[apiName])
        XCTAssertEqual(apiPlugin.pluginConfig.endpoints[apiName]?.interceptors.count, 0)

        let provider = BasicUserPoolTokenProvider(authService: authService)
        let requestInterceptor = UserPoolURLRequestInterceptor(userPoolTokenProvider: provider)
        try apiPlugin.add(interceptor: requestInterceptor, for: apiName)

        XCTAssertEqual(apiPlugin.pluginConfig.endpoints[apiName]?.interceptors.count, 1)
    }
}
