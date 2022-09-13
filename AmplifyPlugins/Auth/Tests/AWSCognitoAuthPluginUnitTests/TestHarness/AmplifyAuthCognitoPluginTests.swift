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

    let apiTimeout = 1.0
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
                beginTest(for: authTestHarness.plugin,
                          with: authTestHarness)
            }
        }
    }

    func beginTest(
        for plugin: AWSCognitoAuthPlugin,
        with testHarness: AuthTestHarness) {

            switch testHarness.apiUnderTest {
            case .resetPassword(let resetPasswordRequest,
                                let expectedOutput):
                validateAPI(expectedOutput: expectedOutput) {
                    return try await plugin.resetPassword(
                        for: resetPasswordRequest.username,
                        options: .init())
                }
            }
        }

    
    // Helper to validate API Result
    func validateAPI<T: Equatable>(
        expectedOutput: Result<T, AuthError>?,
        apiCall: @escaping () async throws -> T) {

            let expectation = expectation(description: "Reset password expectation")
            Task {
                do {
                    let result = try await apiCall()
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
            wait(for: [expectation], timeout: apiTimeout)
        }
}
