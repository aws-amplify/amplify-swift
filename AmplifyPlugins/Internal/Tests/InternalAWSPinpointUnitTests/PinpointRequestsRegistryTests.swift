//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import XCTest
import SmithyHTTPAPI
import Smithy

class PinpointRequestsRegistryTests: XCTestCase {
    private var mockedHttpSdkClient: MockHttpClientEngine!
    private var pinpointConfiguration: PinpointClient.PinpointClientConfiguration!

    override func setUpWithError() throws {
        mockedHttpSdkClient = MockHttpClientEngine()
        pinpointConfiguration = try .init(region: "us-east-1")
        pinpointConfiguration.httpClientEngine = mockedHttpSdkClient
    }

    func testSetCustomHttpEngine_shouldReplaceConfigurationHttpEngine() throws {
        let oldHttpClientEngine = pinpointConfiguration.httpClientEngine
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: pinpointConfiguration)

        XCTAssertNotEqual(oldHttpClientEngine.typeString,
                          pinpointConfiguration.httpClientEngine.typeString)
    }

    func testExecute_withSourcesRegistered_shouldAppendSuffixToUserAgent() async throws {
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: pinpointConfiguration)

        await PinpointRequestsRegistry.shared.registerSource(.analytics, for: .recordEvent)
        await PinpointRequestsRegistry.shared.registerSource(.pushNotifications, for: .recordEvent)
        let sdkRequest = try createSdkRequest(for: .recordEvent)
        _ = try await httpClientEngine.send(request: sdkRequest)
        let executedRequest = mockedHttpSdkClient.request

        XCTAssertEqual(mockedHttpSdkClient.executeCount, 1)
        let userAgent = try XCTUnwrap(
            executedRequest?.headers.value(for: "User-Agent")
        )
        XCTAssertTrue(userAgent.contains(AWSPinpointSource.analytics.rawValue))
        XCTAssertTrue(userAgent.contains(AWSPinpointSource.pushNotifications.rawValue))
    }

    func testExecute_withoutSourcesRegistered_shouldNotAppendSuffixToUserAgent() async throws {
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: pinpointConfiguration)

        await PinpointRequestsRegistry.shared.registerSource(.analytics, for: .recordEvent)
        await PinpointRequestsRegistry.shared.registerSource(.pushNotifications, for: .recordEvent)
        let sdkRequest = try createSdkRequest(for: nil)
        let oldUserAgent = sdkRequest.headers.value(for: "User-Agent")

        _ = try await httpClientEngine.send(request: sdkRequest)
        let executedRequest = mockedHttpSdkClient.request

        XCTAssertEqual(mockedHttpSdkClient.executeCount, 1)
        let newUserAgent = try XCTUnwrap(
            executedRequest?.headers.value(for: "User-Agent")
        )

        XCTAssertEqual(newUserAgent, oldUserAgent)
        XCTAssertFalse(newUserAgent.contains(AWSPinpointSource.analytics.rawValue))
        XCTAssertFalse(newUserAgent.contains(AWSPinpointSource.pushNotifications.rawValue))
    }

    private var httpClientEngine: HTTPClient {
        pinpointConfiguration.httpClientEngine
    }

    private func createSdkRequest(for api: PinpointRequestsRegistry.API?) throws -> HTTPRequest {
        let apiPath = api?.rawValue ?? "otherApi"
        let endpoint = try Endpoint(
            urlString: "https://host:42/path/\(apiPath)/suffix",
            headers: .init(["User-Agent": "mocked_user_agent"])
        )
        return HTTPRequest(
            method: .put,
            endpoint: endpoint
        )
    }
}

private extension HTTPClient {
    var typeString: String {
        String(describing: type(of: self))
    }
}

private class MockHttpClientEngine: HTTPClient {
    var executeCount = 0
    var request: HTTPRequest?

    func send(request: HTTPRequest) async throws -> HTTPResponse {
        executeCount += 1
        self.request = request
        return .init(body: .empty, statusCode: .accepted)
    }

    func close() async {}
}

private class MockLogAgent: LogAgent {
    let name = "MockLogAgent"
    var level: LogAgentLevel = .info

    func log(
        level: Smithy.LogAgentLevel,
        message: @autoclosure () -> String,
        metadata: @autoclosure () -> [String : String]?,
        source: @autoclosure () -> String,
        file: String,
        function: String,
        line: UInt
    ) {
        print("MockLogAgent")
    }
}
