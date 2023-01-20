//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCore
import XCTest

final class AuthorizationProviderAdapterTests: XCTestCase {

    var systemUnderTest: AuthorizationProviderAdapter!
    var mobileClient: MockAWSMobileClient!

    override func setUpWithError() throws {
        mobileClient = MockAWSMobileClient()
        mobileClient.awsCredentialsMockResult = .success(AWSCredentials(accessKey: UUID().uuidString,
                                                                        secretKey: UUID().uuidString,
                                                                        sessionKey: UUID().uuidString,
                                                                        expiration: Date.distantFuture))
        systemUnderTest = AuthorizationProviderAdapter(awsMobileClient: mobileClient)
    }

    override func tearDownWithError() throws {
        mobileClient = nil
        systemUnderTest = nil
    }

    /// - Given: A newly initialized adapter
    /// - When: No other direct interaction has taken place
    /// - Then: The mobile client has received an "addUserStateListener" message
    func testInitializationSideEffects() throws {
        XCTAssertEqual(mobileClient.interactions, ["addUserStateListener(_:_:)"])
    }

    /// - Given: A mobile client user state of "guest"
    /// - When: A fetchSession message is sent to the adapter
    /// - Then: The credentials and identity are requested from the mobile client
    func testFetchSessionForGuest() throws {
        mobileClient.mockCurrentUserState = .guest

        let request = AuthFetchSessionRequest(options: .init())
        let fetchSessionExpectation = expectation(description: "fetchSession")
        systemUnderTest.fetchSession(request: request) { result in
            switch result {
            case .success:
                fetchSessionExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [fetchSessionExpectation], timeout: 1.0)
        XCTAssertEqual(mobileClient.interactions, [
            "addUserStateListener(_:_:)",
            "getCurrentUserState()",
            "getAWSCredentials(_:)",
            "getIdentityId()"
        ])
    }

    /// - Given: A mobile client user state of "signedIn"
    /// - When: A fetchSession message is sent to the adapter
    /// - Then: The session's tokens are requested from the mobile client
    func testFetchSessionForSignedIn() throws {
        mobileClient.mockCurrentUserState = .signedIn

        let request = AuthFetchSessionRequest(options: .init())
        let fetchSessionExpectation = expectation(description: "fetchSession")
        systemUnderTest.fetchSession(request: request) { result in
            switch result {
            case .success:
                fetchSessionExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [fetchSessionExpectation], timeout: 1.0)
        XCTAssertEqual(mobileClient.interactions, [
            "addUserStateListener(_:_:)",
            "getCurrentUserState()",
            "getTokens(_:)"
        ])
    }

    /// - Given: A mobile client user state of "signedOut"
    /// - When: A fetchSession message is sent to the adapter
    /// - Then: The credentials and identity are requested from the mobile client
    func testFetchSessionForSignedOut() throws {
        mobileClient.mockCurrentUserState = .signedOut

        let request = AuthFetchSessionRequest(options: .init())
        let fetchSessionExpectation = expectation(description: "fetchSession")
        systemUnderTest.fetchSession(request: request) { result in
            switch result {
            case .success:
                fetchSessionExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [fetchSessionExpectation], timeout: 1.0)
        XCTAssertEqual(mobileClient.interactions, [
            "addUserStateListener(_:_:)",
            "getCurrentUserState()",
            "getAWSCredentials(_:)",
            "getIdentityId()"
        ])
    }

    /// - Given: Newly initialized adapter
    /// - When: It receives a "invalidateCachedTemporaryCredentials" message
    /// - Then: The "invalidateCachedTemporaryCredentials" is propagated to the mobile client
    func testInvalidateCachedTemporaryCredentials() throws {
        systemUnderTest.invalidateCachedTemporaryCredentials()
        XCTAssertEqual(mobileClient.interactions, [
            "addUserStateListener(_:_:)",
            "invalidateCachedTemporaryCredentials()"
        ])
    }
}
