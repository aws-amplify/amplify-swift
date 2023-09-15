//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class OnRefreshClientMetadataTests: XCTestCase {

    let skipBrokenTests = true

    override func tearDown() async throws {
        await Amplify.reset()
    }

    /// Test plugin's onRefreshClientMetadata can be assigned
    func testEscapeHatchWithUserPoolAndIdentityPool() async throws {
        let plugin = AWSCognitoAuthPlugin(clientMetadataOnCredentialsRefresh: { [weak self] user in
            print(user)
            return await self?.retrieveMetadata() ?? [:]
        })
        let signedInData = SignedInDataOnRefresh(userId: "userId", username: "userName")
        let metadata = await plugin.clientMetadataOnCredentialsRefresh?(signedInData)
        XCTAssertEqual(metadata, ["hello": "world"])
    }
    
    private func retrieveMetadata() async -> [String: String]? {
        return ["hello": "world"]
    }
}
