//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import XCTest

class SyncClientRuntimeVersionTests: CLITestCase {
    
    // MARK: - Helpers
    
    func createGoldenPathEnvironment() throws {
        try! FileManager.default.createDirectory(
            atPath: "aws-sdk-swift",
            withIntermediateDirectories: false
        )
        try! FileManager.default.createDirectory(
            atPath: "smithy-swift",
            withIntermediateDirectories: false
        )
        try! "1.2.3".write(
            toFile: "smithy-swift/Package.version",
            atomically: true,
            encoding: .utf8
        )
        let dependencies = try PackageDependencies(
            awsCRTSwiftVersion: .init("0.0.1"),
            clientRuntimeVersion: .init("0.0.1")
        )
        try! dependencies.save(to: "aws-sdk-swift/\(PackageDependencies.fileName)")
    }
    
    // MARK: - Tests
    
    // MARK: Golden Path
    
    func testGoldenPath() throws {
        try createGoldenPathEnvironment()
        let subject = SyncClientRuntimeVersion.mock(repoPath: "aws-sdk-swift")
        try! subject.run()
        let result = try! PackageDependencies.load()
        try XCTAssertEqual(result.clientRuntimeVersion, .init("1.2.3"))
        try XCTAssertEqual(result.awsCRTSwiftVersion, .init("0.0.1"))
    }
    
    // MARK: resolveSmithySwiftPath()
    
    func testResolveSmithySwiftPathWhenNil() {
        let subject = SyncClientRuntimeVersion.mock()
        let result = subject.resolveSmithySwiftPath()
        XCTAssertEqual(result, "../smithy-swift")
    }
    
    func testResolveSmithySwiftPathWithExplicitPath() {
        let subject = SyncClientRuntimeVersion.mock(smithySwiftPath: "abc")
        let result = subject.resolveSmithySwiftPath()
        XCTAssertEqual(result, "abc")
    }
}

// MARK: - Mocks

extension SyncClientRuntimeVersion {
    static func mock(
        repoPath: String = ".",
        smithySwiftPath: String? = nil
    ) -> Self {
        SyncClientRuntimeVersion(
            repoPath: repoPath,
            smithySwiftPath: smithySwiftPath
        )
    }
}
