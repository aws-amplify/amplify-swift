//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import XCTest

final class AWSCognitoAuthPluginUserDefaultsTests: XCTestCase {

    var systemUnderTest: AWSCognitoAuthPluginUserDefaults!
    var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
        systemUnderTest = AWSCognitoAuthPluginUserDefaults()
        systemUnderTest.defaults = userDefaults
    }

    override func tearDownWithError() throws {
        userDefaults = nil
        systemUnderTest = nil
    }

    /// - Given: A newly-initialized defaults container
    /// - When: Its privateSessionPreferred value is changed
    /// - Then: This change is propagated to the underlying defaults
    func testPreferPrivateSession() throws {
        let defaultValue = systemUnderTest.isPrivateSessionPreferred()
        XCTAssertEqual(defaultValue, false)

        let customValue = !defaultValue
        systemUnderTest.storePreferredBrowserSession(privateSessionPrefered: customValue)

        let updatedValue = systemUnderTest.isPrivateSessionPreferred()
        XCTAssertEqual(updatedValue, customValue)

        XCTAssertEqual(updatedValue, userDefaults.bool(forKey: "AWSCognitoAuthPluginUserDefaults.privateSessionKey"))
    }
}
