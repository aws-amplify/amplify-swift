//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyPluginExtension) @testable import AWSCognitoAuthPlugin
@_spi(InternalAmplifyPluginExtension) import InternalAmplifyCredentials
@testable import InternalAWSCognitoAuth
import XCTest

/// The `UserAgentSuffixAppender: HttpClientEngineProxy` conformance moved from the engine to the
/// plugin. The plugin must still recognise the appender as its engine proxy.
class UserAgentSuffixAppenderProxyTests: XCTestCase {

    /// - Given: A plugin
    /// - When: A `UserAgentSuffixAppender` is added as a plugin extension
    /// - Then: The plugin keeps it as its HTTP client engine proxy
    ///
    func testUserAgentSuffixAppenderIsTheEngineProxy() {
        let plugin = AWSCognitoAuthPlugin()
        let appender = UserAgentSuffixAppender(suffix: "suffix")

        plugin.add(pluginExtension: appender)

        XCTAssertTrue(plugin.httpClientEngineProxy as AnyObject === appender)
    }
}
