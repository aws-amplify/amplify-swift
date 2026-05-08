//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest

@_spi(AmplifyExperimental) @testable import AmplifyCloudWatchLoggingClient
@testable import InternalCloudWatchLogging

private struct MockCredentials: AWSCredentials {
    var accessKeyId: String = "test-access-key"
    var secretAccessKey: String = "test-secret-key"
}

private class MockAWSCredentialsProvider: AWSCredentialsProvider {
    func resolve() async throws -> any AWSCredentials {
        return MockCredentials()
    }
}

final class CloudWatchLoggingSessionTests: XCTestCase {

    /// Given: two AmplifyCloudWatchLoggingClient instances
    ///
    /// - When: both clients emit logs to the same namespace
    /// - Then: they write to different directories on disk
    ///
    func testDifferentClientsUseDifferentDirectories() async throws {
        let client1 = try AmplifyCloudWatchLoggingClient(
            region: "us-east-1",
            credentialsProvider: MockAWSCredentialsProvider(),
            options: .init(logGroupName: "/test/isolation")
        )

        let client2 = try AmplifyCloudWatchLoggingClient(
            region: "us-east-1",
            credentialsProvider: MockAWSCredentialsProvider(),
            options: .init(logGroupName: "/test/isolation")
        )

        XCTAssertNotEqual(client1.id, client2.id)

        // Emit to both with the same namespace
        client1.emit(message: LogMessage(level: .error, name: "Storage", content: "from client 1", error: nil))
        client2.emit(message: LogMessage(level: .error, name: "Storage", content: "from client 2", error: nil))

        try await Task.sleep(nanoseconds: 500_000_000)

        // Verify files exist in separate directories
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir1 = documents.appendingPathComponent("amplify-cloudwatch-client")
                            .appendingPathComponent("logging")
                            .appendingPathComponent(client1.id)
        let dir2 = documents.appendingPathComponent("amplify-cloudwatch-client")
                            .appendingPathComponent("logging")
                            .appendingPathComponent(client2.id)

        XCTAssertNotEqual(dir1, dir2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir1.path), "Client 1 directory should exist at: \(dir1.path)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir2.path), "Client 2 directory should exist at: \(dir2.path)")

        // Cleanup
        await client1.reset()
        await client2.reset()
        let baseDir = documents.appendingPathComponent("amplify-cloudwatch-client")
                               .appendingPathComponent("logging")
        try? FileManager.default.removeItem(at: baseDir.appendingPathComponent(client1.id))
        try? FileManager.default.removeItem(at: baseDir.appendingPathComponent(client2.id))
    }

    /// Given: a single AmplifyCloudWatchLoggingClient
    ///
    /// - When: logs are emitted to multiple namespaces
    /// - Then: each namespace has its own directory under the same client path
    ///
    func testSameClientUsesDifferentDirectoriesForNamespaces() async throws {
        let client = try AmplifyCloudWatchLoggingClient(
            region: "us-east-1",
            credentialsProvider: MockAWSCredentialsProvider(),
            options: .init(logGroupName: "/test/shared")
        )

        client.emit(message: LogMessage(level: .error, name: "Auth", content: "auth log", error: nil))
        client.emit(message: LogMessage(level: .error, name: "Storage", content: "storage log", error: nil))

        try await Task.sleep(nanoseconds: 500_000_000)

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let guestDir = documents.appendingPathComponent("amplify-cloudwatch-client")
                                .appendingPathComponent("logging")
                                .appendingPathComponent(client.id)
                                .appendingPathComponent("guest")

        let authDir = guestDir.appendingPathComponent("auth")
        let storageDir = guestDir.appendingPathComponent("storage")

        XCTAssertNotEqual(authDir, storageDir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: authDir.path), "Auth directory should exist at: \(authDir.path)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: storageDir.path), "Storage directory should exist at: \(storageDir.path)")

        // Cleanup
        await client.reset()
        let clientDir = documents.appendingPathComponent("amplify-cloudwatch-client")
                                 .appendingPathComponent("logging")
                                 .appendingPathComponent(client.id)
        try? FileManager.default.removeItem(at: clientDir)
    }
}
