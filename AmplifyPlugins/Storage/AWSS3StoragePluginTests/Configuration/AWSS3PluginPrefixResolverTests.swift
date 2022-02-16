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

        let resolveComplete = expectation(description: "resolvePrefix completed")
        resolveComplete.expectedFulfillmentCount = 6
        prefixResolver.resolvePrefix(for: .guest, targetIdentityId: nil, completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .protected, targetIdentityId: nil, completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .private, targetIdentityId: nil, completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .guest, targetIdentityId: "targetUserId", completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .protected, targetIdentityId: "targetUserId", completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .private, targetIdentityId: "targetUserId", completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "")
            resolveComplete.fulfill()
        })
        wait(for: [resolveComplete], timeout: 1)
    }

    func testStorageAccessLevelAwarePrefixResolver() {
        let mockAuthService = MockAWSAuthService()
        mockAuthService.identityId = "userId"
        let prefixResolver = StorageAccessLevelAwarePrefixResolver(authService: mockAuthService)

        let resolveComplete = expectation(description: "resolvePrefix completed")
        resolveComplete.expectedFulfillmentCount = 6
        prefixResolver.resolvePrefix(for: .guest, targetIdentityId: nil, completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "public/")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .protected, targetIdentityId: nil, completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "protected/userId/")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .private, targetIdentityId: nil, completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "private/userId/")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .guest, targetIdentityId: "targetUserId", completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "public/")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .protected, targetIdentityId: "targetUserId", completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "protected/targetUserId/")
            resolveComplete.fulfill()
        })
        prefixResolver.resolvePrefix(for: .private, targetIdentityId: "targetUserId", completion: { result in
            self.assertPrefixEquals(result, expectedPrefix: "private/targetUserId/")
            resolveComplete.fulfill()
        })
        wait(for: [resolveComplete], timeout: 1)
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
