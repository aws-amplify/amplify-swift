//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import ClientRuntime
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import XCTest

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
        _ = try await httpClientEngine.execute(request: sdkRequest)

        XCTAssertEqual(mockedHttpSdkClient.executeCount, 1)
        guard let userAgent = sdkRequest.headers.value(for: "User-Agent") else {
            XCTFail("Expected User-Agent")
            return
        }
        XCTAssertTrue(userAgent.contains(AWSPinpointSource.analytics.rawValue))
        XCTAssertTrue(userAgent.contains(AWSPinpointSource.pushNotifications.rawValue))
    }

    func testExecute_withoutSourcesRegistered_shouldNotAppendSuffixToUserAgent() async throws {
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: pinpointConfiguration)

        await PinpointRequestsRegistry.shared.registerSource(.analytics, for: .recordEvent)
        await PinpointRequestsRegistry.shared.registerSource(.pushNotifications, for: .recordEvent)
        let sdkRequest = try createSdkRequest(for: nil)
        let oldUserAgent = sdkRequest.headers.value(for: "User-Agent")

        _ = try await httpClientEngine.execute(request: sdkRequest)

        XCTAssertEqual(mockedHttpSdkClient.executeCount, 1)
        guard let newUserAgent = sdkRequest.headers.value(for: "User-Agent") else {
            XCTFail("Expected User-Agent")
            return
        }

        XCTAssertEqual(newUserAgent, oldUserAgent)
        XCTAssertFalse(newUserAgent.contains(AWSPinpointSource.analytics.rawValue))
        XCTAssertFalse(newUserAgent.contains(AWSPinpointSource.pushNotifications.rawValue))
    }

    private var httpClientEngine: HttpClientEngine {
        pinpointConfiguration.httpClientEngine
    }

    private func createSdkRequest(for api: PinpointRequestsRegistry.API?) throws -> SdkHttpRequest {
        let apiPath = api?.rawValue ?? "otherApi"
        let endpoint = try Endpoint(urlString: "https://host:port/path/\(apiPath)/suffix")
        let headers = [
            "User-Agent": "mocked_user_agent"
        ]
        return SdkHttpRequest(method: .put,
                              endpoint: endpoint,
                              headers: .init(headers))
    }
}

private extension HttpClientEngine {
    var typeString: String {
        String(describing: type(of: self))
    }
}

private class MockSDKRuntimeConfiguration: SDKRuntimeConfiguration {
    let logger: LogAgent
    let retryer: SDKRetryer
    var endpoint: String? = nil
    private let mockedHttpClientEngine : HttpClientEngine

    init(httpClientEngine: HttpClientEngine) throws {
        logger = MockLogAgent()
        retryer = try SDKRetryer(options: .init(backOffRetryOptions: .init()))
        mockedHttpClientEngine = httpClientEngine
    }

    var httpClientEngine: HttpClientEngine {
        mockedHttpClientEngine
    }
}

private class MockHttpClientEngine: HttpClientEngine {
    var executeCount = 0
    func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        executeCount += 1
        return .init(body: .none, statusCode: .accepted)
    }

    func close() async {}
}

private class MockLogAgent: LogAgent {
    let name = "MockLogAgent"
    var level: LogAgentLevel = .info

    func log(level: ClientRuntime.LogAgentLevel, message: String, metadata: [String : String]?, source: String, file: String, function: String, line: UInt) {
    }
}
