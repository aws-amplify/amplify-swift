//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import XCTest

final class AuthenticationProviderAdapterTests: XCTestCase {

    var systemUnderTest: AuthenticationProviderAdapter!
    var mobileClient: MockAWSMobileClient!
    var authUserDefaults: AWSCognitoAuthPluginUserDefaults!

    override func setUpWithError() throws {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)

        mobileClient = MockAWSMobileClient()
        authUserDefaults = AWSCognitoAuthPluginUserDefaults(defaults: userDefaults)
        systemUnderTest = AuthenticationProviderAdapter(awsMobileClient: mobileClient,
                                                        userdefaults: authUserDefaults)
    }

    override func tearDownWithError() throws {
        mobileClient = nil
        authUserDefaults = nil
        systemUnderTest = nil
    }

    /// - Given: A newly-initialized adapter
    /// - When: The current user is requested
    /// - Then: It builds its result from the underlying mobile client's username and userSub
    func testGetCurrentUser() throws {
        let username = UUID().uuidString
        mobileClient.username = username

        let userSub = UUID().uuidString
        mobileClient.userSub = userSub

        let user = try XCTUnwrap(systemUnderTest.getCurrentUser())
        XCTAssertEqual(user.username, username)
        XCTAssertEqual(user.username, username)
        XCTAssertEqual(mobileClient.interactions, [
            "getUsername()",
            "getUserSub()"
        ])
    }
}
