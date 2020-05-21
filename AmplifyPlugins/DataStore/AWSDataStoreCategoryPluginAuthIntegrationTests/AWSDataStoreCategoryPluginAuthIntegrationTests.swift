//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyPlugins
import AWSDataStoreCategoryPlugin

@testable import Amplify
@testable import AmplifyTestCommon

class AWSDataStoreCategoryPluginAuthIntegrationTests: XCTestCase {

    struct User {
        let username: String
        let password: String
    }

    let amplifyConfigurationFile = "AWSDataStoreCategoryPluginAuthIntegrationTests-amplifyconfiguration"
    let credentialsFile = "AWSDataStoreCategoryPluginAuthIntegrationTests-credentials"
    var user1: User!
    var user2: User!

    override func setUp() {
        do {
            let credentials = try TestConfigHelper.retrieveCredentials(forResource: credentialsFile)

            guard let user1 = credentials["user1"],
                let user2 = credentials["user2"],
                let passwordUser1 = credentials["passwordUser1"],
                let passwordUser2 = credentials["passwordUser2"] else {
                    XCTFail("Missing credentials.json data")
                    return
            }

            self.user1 = User(username: user1, password: passwordUser1)
            self.user2 = User(username: user2, password: passwordUser2)

            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: SocialNoteModelRegistration()))
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
        if isSignedIn() {
            signOut()
        }
    }

    override func tearDown() {
        signOut()
        Amplify.reset()
    }

    func testCreateNoteWhileNotAuthenticatedShouldTriggerErrorHandler() {

    }

    /// A note created by the owner should be synced to the other user
    ///
    /// - Given: An auth enabled
    /// - When:
    ///    -
    /// - Then:
    ///    - 
    ///
    func testOwnerNoteShouldSyncToOtherOnlyAfterSignIn() {

    }


    func testExample() {
        // user 1 creates a note.

        // user 1 signs out

        // user 2 is not signed in, query for note, note does not exist
        // user 2 signs in, sync engine starts, note exists.

        // user 2
    }
}
