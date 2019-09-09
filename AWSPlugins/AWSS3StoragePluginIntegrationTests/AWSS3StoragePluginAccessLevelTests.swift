//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import Amplify
import AWSS3StoragePlugin
import AWSS3
import AWSCognitoIdentityProvider

class AWSS3StoragePluginAccessLevelTests: AWSS3StoragePluginTestBase {
    let sharedEmail = "testingUser@amazon.com"
    let userPoolId = "us-east-1_lwhKEyalg"

    let user1 = "storageUser1@testing.com"
    let user2  = "storageUser2@testing.com"
    let commonPassword = "Abc123@@!!"



    func testSetUpOnce() {
        signUpUser(username: user1)
    }

    //    func testPutToPublicAndListThenGetThenRemoveFromOtherUser() {
    //        XCTFail("Not yet implemented")
    //    }
    //

    func testPutToProtectedAndListThenRemoveThenFailGet() {
        signIn(username: user1)
        let key = "testPutToProtectedAndListThenGetThenRemove"
        let dataString = "testPutToProtectedAndListThenGetThenRemove"
        let data = dataString.data(using: .utf8)!

        // Put
        let putExpectation = expectation(description: "Put operation should be successful")
        let putOptions = StoragePutOption(accessLevel: .protected,
                                       contentType: nil,
                                       metadata: nil,
                                       options: nil)
        _ = Amplify.Storage.put(key: key, data: data, options: putOptions) { (event) in
            switch event {
            case .completed:
                putExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to put \(key) with error \(error)")
            default:
                break
            }
        }

        waitForExpectations(timeout: 60)

        // List
        let listExpectation = expectation(description: "List operation should be successful")
        let listOptions = StorageListOption(accessLevel: .protected,
                                            targetIdentityId: nil,
                                            path: key,
                                            limit: nil,
                                            options: nil)
        _ = Amplify.Storage.list(options: listOptions) { (event) in
            switch event {
            case .completed(let results):
                print("results from list: \(results.keys)")
                XCTAssertEqual(results.keys.count, 1, "The result should be 1 since path is set to the key")
                listExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to list from user's own protected folder with error \(error)")
            default:
                break
            }
        }

        let removeExpectation = expectation(description: "Remove Operation should be successful")
        let removeOptions = StorageRemoveOption(accessLevel: .protected, options: nil)
        _ = Amplify.Storage.remove(key: key, options: removeOptions) { (event) in
            switch event {
            case .completed(let results):
                print("results from remove: \(results.key)")
                removeExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to remove with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: 60)

        // Get
        let getFailedExpectation = expectation(description: "Get Operation should fail")
        let getOptions = StorageGetOption(accessLevel: .protected,
                                          targetIdentityId: nil,
                                          storageGetDestination: .data,
                                          options: nil)
        _ = Amplify.Storage.get(key: key, options: getOptions) { (event) in
            switch event {
            case .completed(let results):
                XCTFail("Should not have completed with result \(results)")
            case .failed(let error):
                // TODO: propagate 404's to StorageGetError.data? ("Key is missing", "")
                print("Failed with error \(error)")
                getFailedExpectation.fulfill()
            default:
                break
            }
        }

        waitForExpectations(timeout: 60)
    }
    //
    //    func testPutToProtectedAndListThenGetThenFailRemoveFromOtherUser() {
    //        XCTFail("Not yet implemented")
    //    }
    //
    //    func testPutToPrivateAndListThenGetThenRemove() {
    //        XCTFail("Not yet implemented")
    //    }
    //
    //    func testPutToPrivateAndFailListThenFailGetThenFailRemoveFromOtherUser() {
    //        XCTFail("Not yet implemented")
    //    }

    func signIn(username: String, password: String? = nil, verifySignState: SignInState = .signedIn) {
        let passwordToUse = password ?? commonPassword
        let signInWasSuccessful = expectation(description: "signIn was successful")
        AWSMobileClient.sharedInstance().signIn(username: username, password: passwordToUse) { (signInResult, error) in
            if let error = error {
                XCTFail("User login failed: \(error.localizedDescription)")
                return
            }

            guard let signInResult = signInResult else {
                XCTFail("User login failed, signInResult unexpectedly nil")
                return
            }
            XCTAssertEqual(signInResult.signInState, verifySignState, "Could not verify sign in state")
            signInWasSuccessful.fulfill()
        }
        wait(for: [signInWasSuccessful], timeout: 5)
    }

    // This is pulled in from AWSMobileClient Tests and is not working. Resources created with Amplify CLI do not
    // have admin permissions to verify the user. so for now just go into the console after signUpUser
    func signUpAndVerifyUser(username: String, customUserAttributes: [String: String]? = nil) {
        signUpUser(username: username, customUserAttributes: customUserAttributes)
        adminVerifyUser(username: username)
    }

    func signUpUser(username: String, customUserAttributes: [String: String]? = nil) {
        var userAttributes = ["email": sharedEmail]
        if let customUserAttributes = customUserAttributes {
            userAttributes.merge(customUserAttributes) { current, _ in current }
        }

        let signUpExpectation = expectation(description: "successful sign up expectation.")
        AWSMobileClient.sharedInstance().signUp(
            username: username,
            password: commonPassword/*,
            userAttributes: userAttributes*/) { (signUpResult, error) in
                if let error = error {
                    var errorMessage: String
                    if let mobileClientError = error as? AWSMobileClientError {
                        //errorMessage = mobileClientError.message
                        errorMessage = mobileClientError.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    XCTFail("Unexpected failure: \(errorMessage)")
                    return
                }

                guard let signUpResult = signUpResult else {
                    XCTFail("signUpResult unexpectedly nil")
                    return
                }

                switch(signUpResult.signUpConfirmationState) {
                case .confirmed:
                    print("User is signed up and confirmed.")
                case .unconfirmed:
                    print("""
                        User is not confirmed and needs verification
                        via \(signUpResult.codeDeliveryDetails!.deliveryMedium)
                        sent at \(signUpResult.codeDeliveryDetails!.destination!)
                        """)
                case .unknown:
                    print("Unexpected case")
                }

                XCTAssertTrue(signUpResult.signUpConfirmationState == .unconfirmed, "User is expected to be marked as unconfirmed.")

                signUpExpectation.fulfill()
        }

        wait(for: [signUpExpectation], timeout: 5)
    }

    func adminVerifyUser(username: String) {
        guard let adminConfirmSignUpRequest = AWSCognitoIdentityProviderAdminConfirmSignUpRequest() else {
            XCTFail("Unable to create adminConfirmSignUpRequest")
            return
        }

        adminConfirmSignUpRequest.username = username
        adminConfirmSignUpRequest.userPoolId = userPoolId
        let credentialsProvider = AWSMobileClient.sharedInstance()
        let region = "us-east-1"
        let configuration = AWSServiceConfiguration(region: region.aws_regionTypeValue(), credentialsProvider: credentialsProvider)!
        AWSCognitoIdentityProvider.register(with: configuration, forKey: "TEST")
        let client = AWSCognitoIdentityProvider(forKey: "TEST")
        client.adminConfirmSignUp(adminConfirmSignUpRequest).continueWith(block: { (task) -> Any? in
            if let error = task.error {
                XCTFail("Could not confirm user. Failing the test: \(error)")
            }
            return nil
        }).waitUntilFinished()
    }
}
