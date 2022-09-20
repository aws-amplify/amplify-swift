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
        let testInputFiles = try! FileManager.default.contentsOfDirectory(
            atPath: bundle.resourcePath! + "/" + AuthTestHarnessConstants.testSuitesPath)

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
                    XCTAssertEqual(expectedOutput, Result.success(result))
                    expectation.fulfill()
                } catch let error as AuthError {
                    XCTAssertEqual(expectedOutput, Result.failure(error))
                    expectation.fulfill()
                } catch {
                    XCTFail("Reset password API should throw AuthError")
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: apiTimeout)
        }
}
