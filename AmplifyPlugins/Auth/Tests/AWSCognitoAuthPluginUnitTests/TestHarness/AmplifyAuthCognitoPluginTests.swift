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

class AmplifyAuthCognitoPluginTests: XCTestCase {

    let apiTimeout = 1.0

    func testAuthCognitoPlugin() {

        // Load the json configs
        let bundle = Bundle.authCognitoTestBundle()
        let testSuiteDirectories = try! FileManager.default.contentsOfDirectory(
            atPath: "\(bundle.resourcePath!)/\(AuthTestHarnessConstants.testSuitesPath)")

        for directory in testSuiteDirectories {

            let testSuiteSubdirectoryPath = "\(bundle.resourcePath!)/\(AuthTestHarnessConstants.testSuitesPath)/\(directory)"
            let testSuiteFiles = try! FileManager.default.contentsOfDirectory(
                atPath: testSuiteSubdirectoryPath)

            for testSuiteFile in testSuiteFiles {
                XCTContext.runActivity(named: testSuiteFile) { activity in
                    let specification = FeatureSpecification(
                        fileName: testSuiteFile,
                        subdirectory: "\(AuthTestHarnessConstants.testSuitesPath)/\(directory)")
                    let authTestHarness = AuthTestHarness(featureSpecification: specification)
                    beginTest(for: authTestHarness.plugin,
                              with: authTestHarness)
                }
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
            case .signUp(let signUpRequest,
                         let expectedOutput):
                validateAPI(expectedOutput: expectedOutput) {
                    return try await plugin.signUp(
                        username: signUpRequest.username,
                        password: signUpRequest.password, options: .init())
                }
            case .signIn(let request,
                         let expectedOutput):
                validateAPI(expectedOutput: expectedOutput) {
                    return try await plugin.signIn(
                        username: request.username,
                        password: request.password, options: .init())
                }
            case .deleteUser(_, let expectedOutput):
                let expectation = expectation(description: "expectation")
                Task {
                    do {
                        try await plugin.deleteUser()
                        expectation.fulfill()
                    } catch let error as AuthError {
                        if case .failure(let expectedError) = expectedOutput {
                            XCTAssertEqual(error, expectedError)
                        } else {
                            XCTFail("API should not throw AuthError")
                        }
                        expectation.fulfill()
                    } catch {
                        XCTFail("API should not throw AuthError")
                        expectation.fulfill()
                    }
                }
                wait(for: [expectation], timeout: apiTimeout)
            case .confirmSignIn(let request, expectedOutput: let expectedOutput):
                validateAPI(expectedOutput: expectedOutput) {
                    return try await plugin.confirmSignIn(
                        challengeResponse: request.challengeResponse)
                }
            }

        }

    
    // Helper to validate API Result
    func validateAPI<T: Equatable>(
        expectedOutput: Result<T, AuthError>?,
        apiCall: @escaping () async throws -> T) {

            let expectation = expectation(description: "expectation")
            Task {
                do {
                    let result = try await apiCall()
                    XCTAssertEqual(expectedOutput, Result.success(result))
                    expectation.fulfill()
                } catch let error as AuthError {
                    XCTAssertEqual(expectedOutput, Result.failure(error))
                    expectation.fulfill()
                } catch {
                    XCTFail("API should not throw AuthError")
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: apiTimeout)
        }
}
