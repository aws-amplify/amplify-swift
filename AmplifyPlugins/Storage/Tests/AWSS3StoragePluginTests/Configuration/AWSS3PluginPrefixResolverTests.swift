//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin
@testable import AWSPluginsTestCommon

extension Sequence where Element == PrefixTestData {
    /// Convert to asynchronous sequence.
    var async: AmplifyAsyncSequence<Self.Element> {
        let sequence = AmplifyAsyncSequence<Self.Element>()
        for element in self {
            sequence.send(element)
        }
        return sequence
    }
}

struct PrefixTestData {
    let accessLevel: StorageAccessLevel
    let targetIdentityId: String?
    let expectedPrefix: String
    let file: StaticString
    let line: UInt

    init(_ accessLevel: StorageAccessLevel, _ targetIdentityId: String?, _ expectedPrefix: String,
         file: StaticString = #filePath, line: UInt = #line) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.expectedPrefix = expectedPrefix
        self.file = file
        self.line = line
    }

    func assertEqual(prefixResolver: AWSS3PluginPrefixResolver) async throws {
        let prefix = try await prefixResolver.resolvePrefix(for: accessLevel, targetIdentityId: targetIdentityId)
        XCTAssertEqual(prefix, expectedPrefix, file: file, line: line)
    }
}

class AWSS3PluginPrefixResolverTests: XCTestCase {

    func testPassthroughPrefixResolver() async throws {
        let prefixResolver = PassThroughPrefixResolver()

        let testData: [PrefixTestData] = [
            .init(.guest, nil, ""),
            .init(.protected, nil, ""),
            .init(.private, nil, ""),
            .init(.guest, "identityId", ""),
            .init(.protected, "identityId", ""),
            .init(.private, "identityId", ""),
        ]

        let done = asyncExpectation(description: "done", expectedFulfillmentCount: testData.count)
        Task {
            try await testData.async.forEach {
                try await $0.assertEqual(prefixResolver: prefixResolver)
                await done.fulfill()
            }
        }
        await waitForExpectations([done])
    }

    func testStorageAccessLevelAwarePrefixResolver() async throws {
        let mockAuthService = MockAWSAuthService()
        mockAuthService.identityId = "userId"
        let prefixResolver = StorageAccessLevelAwarePrefixResolver(authService: mockAuthService)

        let testData: [PrefixTestData] = [
            .init(.guest, nil, "public/"),
            .init(.protected, nil, "protected/userId/"),
            .init(.private, nil, "private/userId/"),
            .init(.guest, "targetUserId", "public/"),
            .init(.protected, "targetUserId", "protected/targetUserId/"),
            .init(.private, "targetUserId", "private/targetUserId/"),
        ]

        let done = asyncExpectation(description: "done", expectedFulfillmentCount: testData.count)
        Task {
            try await testData.async.forEach {
                try await $0.assertEqual(prefixResolver: prefixResolver)
                await done.fulfill()
            }
        }
        await waitForExpectations([done])
    }

}
