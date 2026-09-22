//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import InternalAmplifyCredentials
import XCTest
@testable import AWSAPIPlugin

// swiftlint:disable:next type_name
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSAPICategoryPluginInterceptorBehaviorTests: AWSAPICategoryPluginTestBase, @unchecked Sendable {

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
