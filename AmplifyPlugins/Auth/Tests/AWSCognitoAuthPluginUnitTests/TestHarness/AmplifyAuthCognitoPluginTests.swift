//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import AmplifyTestCommon

class AmplifyAuthCognitoPluginTests: XCTestCase {

    let apiTimeout = 2.0
    let testSuitesResourcePath = "/TestResources/TestSuites"

    func testAuthCognitoPlugin() {

        // Load the json configs
        let bundle = Bundle.authCognitoTestBundle()
        let testInputFiles = try! FileManager.default.contentsOfDirectory(
            atPath: bundle.resourcePath! + testSuitesResourcePath)

        for testInputFile in testInputFiles {
            XCTContext.runActivity(named: testInputFile) { activity in
                let specification = FeatureSpecification.init(fileName: testInputFile)
                let authTestHarness = AuthTestHarness(featureSpecification: specification)
                beginTest(with: authTestHarness)
            }
        }
    }

    func beginTest(with testHarness: AuthTestHarness) {

        switch testHarness.testHarnessInput.amplifyAPI {
            case .resetPassword(let resetPasswordRequest,
                                let expectedOutput):
            validateResetPasswordAPI(
                plugin: testHarness.getPlugin(),
                request: resetPasswordRequest,
                expectedOutput: expectedOutput)
        }
    }

    func validateResetPasswordAPI(
        plugin: AWSCognitoAuthPlugin,
        request: AuthResetPasswordRequest,
        expectedOutput: Result<AuthResetPasswordResult, AuthError>?) {


            let expectation = expectation(description: "Reset password expectation")

            Task {
                do {
                    let result = try await plugin.resetPassword(
                        for: request.username,
                        options: .init())
                    if let expectedOutput = expectedOutput {
                        switch expectedOutput {
                        case .success(let expectedResult):
                            XCTAssertEqual(expectedResult, result)
                        case .failure(_):
                            XCTFail("Reset Password API should throw an error")
                        }
                    }
                    expectation.fulfill()

                } catch let error as AuthError {
                    if let expectedOutput = expectedOutput {
                        switch expectedOutput {
                        case .success(_):
                            XCTFail("Reset Password API should not throw an error: \(error)")
                        case .failure(let expectedError):
                            XCTAssertEqual(expectedError, error)
                        }
                    }

                    expectation.fulfill()
                } catch {
                    XCTFail("Reset password API should throw AuthError")
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 1)

        }


//    func validateChangePasswordAPI(
//        plugin: AWSCognitoAuthPlugin,
//        request: UpdatePasswordAPI.Request,
//        response: UpdatePasswordAPI.Response) async {
//
//            let resultExpectation = expectation(description: "Should receive a result")
//
//
//            do {
//                let result = try await plugin.update(
//                    oldPassword: request.oldPassword,
//                    to: request.newPassword)
//                resultExpectation.fulfill()
//            } catch {
//
//            }
//
//            wait(for: [resultExpectation], timeout: apiTimeout)
//        }

}
