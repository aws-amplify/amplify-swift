//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyPluginExtension) 
@_spi(PluginHTTPClientEngine)
@_spi(InternalHttpEngineProxy)
import InternalAmplifyCredentials
import ClientRuntime
import XCTest

class UserAgentSettingClientEngineTestCase: XCTestCase {
    let userAgentKey = "User-Agent"

    /// Given: A `UserAgentSettingClientEngine`.
    /// When: A request is invoked **with** an existing User-Agent.
    /// Then: The `lib` component of the user-agent is added.
    func test_existingUserAgent_addsLibComponent() async throws {
        let request: SdkHttpRequest = .mock
        let existingUserAgent = "foo/bar/baz"
        request.withHeader(name: userAgentKey, value: existingUserAgent)

        let target = MockTargetEngine()
        let engine = UserAgentSettingClientEngine(target: target)
        _ = try await engine.send(request: request)
        let userAgent = try XCTUnwrap(target.request?.headers.value(for: userAgentKey))

        XCTAssertEqual(
            userAgent,
            "\(existingUserAgent) \(AmplifyAWSServiceConfiguration.userAgentLib)"
        )
    }

    /// Given: A `UserAgentSettingClientEngine`.
    /// When: A request is invoked **without** existing User-Agent.
    /// Then: The `lib` component of the user-agent is added.
    func test_nonExistingUserAgent_addsLibComponent() async throws {
        let request: SdkHttpRequest = .mock
        let target = MockTargetEngine()
        let engine = UserAgentSettingClientEngine(target: target)
        _ = try await engine.send(request: request)
        let userAgent = try XCTUnwrap(target.request?.headers.value(for: userAgentKey)).trim()

        XCTAssertEqual(userAgent, AmplifyAWSServiceConfiguration.userAgentLib)
    }

    /// Given: A `UserAgentSettingClientEngine` targeting a `UserAgentSuffixAppender`.
    /// When: A request is invoked **with** existing User-Agent.
    /// Then: The `lib` component of the user-agent and the suffix are added.
    func test_existingUserAgentCombinedWithSuffixAppender_addLibAndSuffix() async throws {
        let request: SdkHttpRequest = .mock
        let existingUserAgent = "foo/bar/baz"
        request.withHeader(name: userAgentKey, value: existingUserAgent)

        let target = MockTargetEngine()
        let suffix = "a/b/c"
        let suffixAppender = UserAgentSuffixAppender(suffix: suffix)
        suffixAppender.target = target
        let engine = UserAgentSettingClientEngine(target: suffixAppender)

        _ = try await engine.send(request: request)
        let userAgent = try XCTUnwrap(target.request?.headers.value(for: userAgentKey))
        XCTAssertEqual(
            userAgent,
            "\(existingUserAgent) \(AmplifyAWSServiceConfiguration.userAgentLib) \(suffix)"
        )
    }

    /// Given: A `UserAgentSettingClientEngine` targeting a `UserAgentSuffixAppender`.
    /// When: A request is invoked **without** existing User-Agent.
    /// Then: The `lib` component of the user-agent and the suffix are added.
    func test_nonExistingUserAgentCombinedWithSuffixAppender_addLibAndSuffix() async throws {
        let request: SdkHttpRequest = .mock

        let target = MockTargetEngine()
        let suffix = "a/b/c"
        let suffixAppender = UserAgentSuffixAppender(suffix: suffix)
        suffixAppender.target = target
        let engine = UserAgentSettingClientEngine(target: suffixAppender)

        _ = try await engine.send(request: request)
        let userAgent = try XCTUnwrap(target.request?.headers.value(for: userAgentKey)).trim()
        XCTAssertEqual(
            userAgent,
            "\(AmplifyAWSServiceConfiguration.userAgentLib) \(suffix)"
        )
    }
}

class MockTargetEngine: HTTPClient {
    var request: SdkHttpRequest?

    func send(
        request: SdkHttpRequest
    ) async throws -> HttpResponse {
        self.request = request
        return .init(body: .empty, statusCode: .accepted)
    }
}

extension SdkHttpRequest {
    static var mock: SdkHttpRequest {
        .init(
            method: .get,
            endpoint: .init(host: "amplify")
        )
    }
}
