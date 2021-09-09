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

class AWSS3PluginPrefixResolverTests: XCTestCase {

    func testPassthroughPrefixResolver() {
        let prefixResolver = PassThroughPrefixResolver()

        assertPrefixEquals(prefixResolver.resolvePrefix(for: .guest, targetIdentityId: nil), expectedPrefix: "")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .protected, targetIdentityId: nil), expectedPrefix: "")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .private, targetIdentityId: nil), expectedPrefix: "")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .guest, targetIdentityId: "identityId"),
                           expectedPrefix: "")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .protected, targetIdentityId: "identityId"),
                           expectedPrefix: "")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .private, targetIdentityId: "identityId"),
                           expectedPrefix: "")
    }

    func testStorageAccessLevelAwarePrefixResolver() {
        let mockAuthService = MockAWSAuthService()
        mockAuthService.identityId = "userId"
        let prefixResolver = StorageAccessLevelAwarePrefixResolver(authService: mockAuthService)

        assertPrefixEquals(prefixResolver.resolvePrefix(for: .guest, targetIdentityId: nil),
                           expectedPrefix: "public/")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .protected, targetIdentityId: nil),
                           expectedPrefix: "protected/userId/")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .private, targetIdentityId: nil),
                           expectedPrefix: "private/userId/")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .guest, targetIdentityId: "targetUserId"),
                           expectedPrefix: "public/")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .protected, targetIdentityId: "targetUserId"),
                           expectedPrefix: "protected/targetUserId/")
        assertPrefixEquals(prefixResolver.resolvePrefix(for: .private, targetIdentityId: "targetUserId"),
                           expectedPrefix: "private/targetUserId/")

    }

    func assertPrefixEquals(_ result: Result<String, StorageError>, expectedPrefix: String) {
        switch result {
        case .success(let prefix):
            XCTAssertEqual(prefix, expectedPrefix)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
}
