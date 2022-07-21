//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import AWSAPIPlugin

@testable import Amplify
// @testable import AWSAPICategoryPluginTestCommon
@testable import APIHostApp

extension GraphQLAuthDirectiveIntegrationTests {

    func signIn(username: String, password: String) {
        let signInInvoked = expectation(description: "sign in completed")
        _ = Amplify.Auth.signIn(username: username, password: password) { event in
            switch event {
            case .success:
                signInInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to Sign in user \(error)")
            }
        }
        wait(for: [signInInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func signOut() {
        let signOutCompleted = expectation(description: "sign out completed")
        _ = Amplify.Auth.signOut { event in
            switch event {
            case .success:
                signOutCompleted.fulfill()
            case .failure(let error):
                print("Could not sign out user \(error)")
                signOutCompleted.fulfill()
            }
        }
        wait(for: [signOutCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func getIdentityId() -> String {
        let retrieveIdentityCompleted = expectation(description: "retrieve identity completed")
        var resultOptional: String?
        _ = Amplify.Auth.fetchAuthSession(listener: { event in
            switch event {
            case .success(let authSession):
                guard let cognitoAuthSession = authSession as? AuthCognitoIdentityProvider else {
                    XCTFail("Could not get auth session as AuthCognitoIdentityProvider")
                    return
                }
                switch cognitoAuthSession.getIdentityId() {
                case .success(let identityId):
                    resultOptional = identityId
                    retrieveIdentityCompleted.fulfill()
                case .failure(let error):
                    XCTFail("Failed to get auth session \(error)")
                }
            case .failure(let error):
                XCTFail("Failed to get auth session \(error)")
            }
        })
        wait(for: [retrieveIdentityCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Could not get identityId for user")
        }

        return result
    }

    func getUserSub() -> String {
        let retrieveUserSubCompleted = expectation(description: "retrieve userSub completed")
        var resultOptional: String?
        _ = Amplify.Auth.fetchAuthSession(listener: { event in
            switch event {
            case .success(let authSession):
                guard let cognitoAuthSession = authSession as? AuthCognitoIdentityProvider else {
                    XCTFail("Could not get auth session as AuthCognitoIdentityProvider")
                    return
                }
                switch cognitoAuthSession.getUserSub() {
                case .success(let userSub):
                    resultOptional = userSub
                    retrieveUserSubCompleted.fulfill()
                case .failure(let error):
                    XCTFail("Failed to get auth session \(error)")
                }
            case .failure(let error):
                XCTFail("Failed to get auth session \(error)")
            }
        })
        wait(for: [retrieveUserSubCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Could not get userSub for user")
        }

        return result
    }

    func isSignedIn() -> Bool {
        let checkIsSignedInCompleted = expectation(description: "retrieve auth session completed")
        var resultOptional: Bool?
        _ = Amplify.Auth.fetchAuthSession { event in
            switch event {
            case .success(let authSession):
                resultOptional = authSession.isSignedIn
                checkIsSignedInCompleted.fulfill()
            case .failure(let error):
                fatalError("Failed to get auth session \(error)")
            }
        }
        wait(for: [checkIsSignedInCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Could not get isSignedIn for user")
        }

        return result
    }
}
