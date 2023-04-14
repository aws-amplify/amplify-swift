//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyPluginExtension) @_spi(InternalHttpEngineProxy) import AWSPluginsCore
import ClientRuntime
import XCTest

class UserAgentSuffixAppenderTests: XCTestCase {
    private let userAgentKey = "User-Agent"
    private let customSuffix = "myCustomSuffix"
    private var appender: UserAgentSuffixAppender!
    private var httpClientEngine: MockHttpClientEngine!

    override func setUp() {
        appender = UserAgentSuffixAppender(suffix: customSuffix)
        httpClientEngine = MockHttpClientEngine()
        appender.target = httpClientEngine
    }

    override func tearDown() {
        appender = nil
        httpClientEngine = nil
    }

    /// Given: A UserAgentSuffixAppender with a configured httpClientEngine
    /// When: A request is invoked with an existing User-Agent
    /// Then: The user agent suffix is appended
    func testExecute_withExistingUserAgentHeader_shouldAppendSuffix() async throws {
        let request = createRequest()
        request.headers.add(name: userAgentKey, value: "existingUserAgent")

        _ = try await appender.execute(request: request)
        XCTAssertEqual(httpClientEngine.executeCount, 1)
        XCTAssertNotNil(httpClientEngine.executeRequest)
        let userAgent = try XCTUnwrap(request.headers.value(for: userAgentKey))
        XCTAssertTrue(userAgent.hasSuffix(customSuffix))
    }

    /// Given: A UserAgentSuffixAppender with a configured httpClientEngine
    /// When: A request is invoked with no User-Agent
    /// Then: The user agent is created containing the suffix
    func testExecute_withoutExistingUserAgentHeader_shouldCreateHeader() async throws {
        let request = createRequest()

        _ = try await appender.execute(request: request)
        XCTAssertEqual(httpClientEngine.executeCount, 1)
        XCTAssertNotNil(httpClientEngine.executeRequest)
        let userAgent = try XCTUnwrap(request.headers.value(for: userAgentKey))
        XCTAssertTrue(userAgent.hasSuffix(customSuffix))
    }

    /// Given: A UserAgentSuffixAppender with no httpClientEngine configured
    /// When: A request is invoked
    /// Then: An error is thrown
    func testExecute_withoutHttpClientEngine_shouldThrowError() async {
        appender = UserAgentSuffixAppender(suffix: customSuffix)
        do {
            _ = try await appender.execute(request: createRequest())
            XCTFail("Should not succeed")
        } catch {
            guard case ClientError.unknownError(_) = error else {
                XCTFail("Expected .unknownError, got \(error)")
                return
            }
        }
    }

    /// Given: A UserAgentSuffixAppender with a configured httpClientEngine
    /// When: close is invoked
    /// Then: The httpClientEngine's close API should be called
    func testClose_shouldInvokeClose() async {
        await appender.close()
        XCTAssertEqual(httpClientEngine.closeCount, 1)
    }

    private func createRequest() -> SdkHttpRequest {
        return SdkHttpRequest(
            method: .get,
            endpoint: .init(host: "customHost"),
            headers: .init()
        )
    }
}

private class MockHttpClientEngine: HttpClientEngine {
    var executeCount = 0
    var executeRequest: SdkHttpRequest?
    func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        executeCount += 1
        executeRequest = request
        return .init(body: .empty, statusCode: .accepted)
    }

    var closeCount = 0
    func close() async {
        closeCount += 1
    }
}
