//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
import AWSPluginsCore

// swiftlint:disable:next type_name
class AWSAPICategoryPluginInterceptorBehaviorTests: AWSAPICategoryPluginTestBase {

    func testAddInterceptor() throws {
        XCTAssertNotNil(apiPlugin.pluginConfig.endpoints[apiName])
        XCTAssertEqual(apiPlugin.pluginConfig.interceptorsForEndpoint(named: apiName)?.preludeInterceptors.count, 0)
        XCTAssertEqual(apiPlugin.pluginConfig.interceptorsForEndpoint(named: apiName)?.interceptors.count, 0)
        XCTAssertEqual(apiPlugin.pluginConfig.interceptorsForEndpoint(named: apiName)?.postludeInterceptors.count, 0)

        let provider = BasicUserPoolTokenProvider(authService: authService)
        let requestInterceptor = AuthTokenURLRequestInterceptor(authTokenProvider: provider)
        try apiPlugin.add(interceptor: requestInterceptor, for: apiName)

        XCTAssertEqual(apiPlugin.pluginConfig.interceptorsForEndpoint(named: apiName)?.preludeInterceptors.count, 0)
        XCTAssertEqual(apiPlugin.pluginConfig.interceptorsForEndpoint(named: apiName)?.interceptors.count, 1)
        XCTAssertEqual(apiPlugin.pluginConfig.interceptorsForEndpoint(named: apiName)?.postludeInterceptors.count, 0)
    }
}
