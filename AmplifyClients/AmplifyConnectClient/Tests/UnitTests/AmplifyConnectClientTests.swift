//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyConnectClient
import AmplifyFoundation
import Foundation
import XCTest

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
@MainActor
final class AmplifyConnectClientTests: XCTestCase {

    private func makeClient(
        signer: MockRequestSigner = MockRequestSigner(),
        httpClient: MockHTTPClient = MockHTTPClient()
    ) -> AmplifyConnectClient {
        AmplifyConnectClient(
            domainName: "test-domain",
            region: "us-east-1",
            credentialsProvider: MockCredentialsProvider(),
            requestSigner: signer,
            httpClient: httpClient
        )
    }

    /// Test that identifyUser sends the correct payload
    ///
    /// - Given: A client with a mock signer and HTTP client
    /// - When:
    ///    - identifyUser is called with a userId and profile
    /// - Then:
    ///    - The request body contains the correct action and user data
    ///
    func testIdentifyUserSendsCorrectPayload() async throws {
        let signer = MockRequestSigner()
        let client = makeClient(signer: signer)

        try await client.identifyUser(
            userId: "user-123",
            userProfile: UserProfile(email: "test@example.com", name: "Test User")
        )

        let body = try JSONSerialization.jsonObject(with: signer.lastSignedRequest!.body!) as! [String: Any]
        XCTAssertEqual(body["action"] as? String, "identifyUser")
        XCTAssertEqual(body["userId"] as? String, "user-123")
        let profile = body["userProfile"] as! [String: Any]
        XCTAssertEqual(profile["email"] as? String, "test@example.com")
        XCTAssertEqual(profile["name"] as? String, "Test User")
    }

    /// Test that registerDevice includes deviceId and token
    ///
    /// - Given: A client with a mock signer
    /// - When:
    ///    - registerDevice is called with a device token
    /// - Then:
    ///    - The request contains action, deviceId, deviceToken, and channelType
    ///
    func testRegisterDeviceSendsCorrectPayload() async throws {
        let signer = MockRequestSigner()
        let client = makeClient(signer: signer)

        try await client.registerDevice(
            deviceToken: "apns-device-token-123",
            channelType: "APNS"
        )

        let body = try JSONSerialization.jsonObject(with: signer.lastSignedRequest!.body!) as! [String: Any]
        XCTAssertEqual(body["action"] as? String, "registerDevice")
        XCTAssertEqual(body["deviceToken"] as? String, "apns-device-token-123")
        XCTAssertEqual(body["channelType"] as? String, "APNS")
        XCTAssertNotNil(body["deviceId"] as? String)
        XCTAssertFalse((body["deviceId"] as! String).isEmpty)
    }

    /// Test that removeDevice sends the correct action
    ///
    /// - Given: A client with a mock signer
    /// - When:
    ///    - removeDevice is called
    /// - Then:
    ///    - The request contains action and deviceId
    ///
    func testRemoveDeviceSendsCorrectPayload() async throws {
        let signer = MockRequestSigner()
        let client = makeClient(signer: signer)

        try await client.removeDevice()

        let body = try JSONSerialization.jsonObject(with: signer.lastSignedRequest!.body!) as! [String: Any]
        XCTAssertEqual(body["action"] as? String, "removeDevice")
        XCTAssertNotNil(body["deviceId"] as? String)
    }

    /// Test that missing signer throws configuration error
    ///
    /// - Given: A client with no signer
    /// - When:
    ///    - identifyUser is called
    /// - Then:
    ///    - A ConnectClientError.configuration is thrown
    ///
    func testMissingSignerThrowsError() async throws {
        let client = AmplifyConnectClient(
            domainName: "test-domain",
            region: "us-east-1",
            credentialsProvider: MockCredentialsProvider(),
            requestSigner: nil,
            httpClient: MockHTTPClient()
        )

        do {
            try await client.identifyUser(userId: "user-123")
            XCTFail("Expected error")
        } catch let error as ConnectClientError {
            guard case .configuration = error else {
                XCTFail("Expected configuration error, got \(error)")
                return
            }
        }
    }

    /// Test that the signer receives the correct service and region
    ///
    /// - Given: A client configured with region us-east-1
    /// - When:
    ///    - identifyUser is called
    /// - Then:
    ///    - The signer is called with service "profile" and region "us-east-1"
    ///
    func testSignerReceivesCorrectServiceAndRegion() async throws {
        let signer = MockRequestSigner()
        let client = makeClient(signer: signer)

        try await client.identifyUser(userId: "user-123")

        XCTAssertEqual(signer.lastRegion, "us-east-1")
        XCTAssertEqual(signer.lastService, "profile")
    }

    /// Test that device ID is stable across calls
    ///
    /// - Given: A client
    /// - When:
    ///    - registerDevice is called twice
    /// - Then:
    ///    - Both calls use the same deviceId
    ///
    func testDeviceIdIsStableAcrossCalls() async throws {
        let signer = MockRequestSigner()
        let client = makeClient(signer: signer)

        try await client.registerDevice(deviceToken: "token-1")
        let body1 = try JSONSerialization.jsonObject(with: signer.lastSignedRequest!.body!) as! [String: Any]
        let deviceId1 = body1["deviceId"] as! String

        try await client.registerDevice(deviceToken: "token-2")
        let body2 = try JSONSerialization.jsonObject(with: signer.lastSignedRequest!.body!) as! [String: Any]
        let deviceId2 = body2["deviceId"] as! String

        XCTAssertEqual(deviceId1, deviceId2)
    }

    /// Test that non-2xx response throws request error
    ///
    /// - Given: A client whose HTTP client returns 500
    /// - When:
    ///    - identifyUser is called
    /// - Then:
    ///    - A ConnectClientError.request is thrown
    ///
    func testNon2xxResponseThrowsError() async throws {
        let httpClient = MockHTTPClient(statusCode: 500)
        let client = makeClient(httpClient: httpClient)

        do {
            try await client.identifyUser(userId: "user-123")
            XCTFail("Expected error")
        } catch let error as ConnectClientError {
            guard case .request = error else {
                XCTFail("Expected request error, got \(error)")
                return
            }
        }
    }
}

// MARK: - Test Helpers

private struct MockCredentialsProvider: AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials {
        MockAWSCredentials()
    }
}

private struct MockAWSCredentials: AWSCredentials {
    var accessKeyId: String { "test-access-key" }
    var secretAccessKey: String { "test-secret-key" }
}

final class MockRequestSigner: RequestSigner, @unchecked Sendable {
    var lastSignedRequest: SignableRequest?
    var lastRegion: String?
    var lastService: String?

    func sign(
        request: SignableRequest,
        credentials: AWSCredentials,
        region: String,
        service: String
    ) async throws -> [String: String] {
        lastSignedRequest = request
        lastRegion = region
        lastService = service
        return [
            "Authorization": "AWS4-HMAC-SHA256 Credential=test",
            "Content-Type": "application/json",
        ]
    }
}

final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    let statusCode: Int
    var lastRequest: URLRequest?

    init(statusCode: Int = 200) {
        self.statusCode = statusCode
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        return (Data(), response)
    }
}
