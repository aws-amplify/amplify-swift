//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class SetUpTOTPTaskTests: BasePluginTest {

    /// Test a successful set up TOTP call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke setUpTOTP
    /// - Then:
    ///    - I should get a successful result with a secret
    ///
    func testSuccessfulSetUpTOTPRequest() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                return .init(secretCode: "secretCode")
            })

        do {
            let setUpTOTPResult = try await plugin.setUpTOTP(options: nil)
            XCTAssertEqual(setUpTOTPResult.secretCode, "secretCode")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    // MARK: Service error handling test

    /// Test a setUpTOTP call with concurrentModificationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   concurrentModificationException response
    /// - When:
    ///    - I invoke setUpTOTP with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSetUpTOTPWithConcurrentModificationException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                throw AssociateSoftwareTokenOutputError
                    .concurrentModificationException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.setUpTOTP(options: nil)
            XCTFail("Should return an error if the result from service is invalid")

        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            XCTAssertNil(underlyingError)
        }

    }

    /// Test a setUpTOTP call with forbiddenException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   forbiddenException response
    /// - When:
    ///    - I invoke setUpTOTP with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSetUpTOTPWithForbiddenException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                throw AssociateSoftwareTokenOutputError
                    .forbiddenException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.setUpTOTP(options: nil)
            XCTFail("Should return an error if the result from service is invalid")

        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            XCTAssertNil(underlyingError)
        }

    }

    /// Test a setUpTOTP call with internalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   internalErrorException response
    /// - When:
    ///    - I invoke setUpTOTP with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSetUpTOTPWithInternalErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                throw AssociateSoftwareTokenOutputError
                    .internalErrorException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.setUpTOTP(options: nil)
            XCTFail("Should return an error if the result from service is invalid")

        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }

    }

    /// Test a setUpTOTP call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke setUpTOTP
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testSetUpTOTPWithInvalidParameterException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                throw AssociateSoftwareTokenOutputError
                    .invalidParameterException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.setUpTOTP(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a setUpTOTP call with notAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   notAuthorizedException response
    ///
    /// - When:
    ///    - I invoke setUpTOTP
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSetUpTOTPWithNotAuthorizedException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                throw AssociateSoftwareTokenOutputError
                    .notAuthorizedException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.setUpTOTP(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized(_, _, _) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
        }
    }

    /// Test a setUpTOTP call with SoftwareTokenMFANotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   SoftwareTokenMFANotFoundException response
    ///
    /// - When:
    ///    - I invoke setUpTOTP
    /// - Then:
    ///    - I should get a .service error with .softwareTokenMFANotEnabled as underlyingError
    ///
    func testSetUpWithSoftwareTokenMFANotFoundException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                throw AssociateSoftwareTokenOutputError
                    .softwareTokenMFANotFoundException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.setUpTOTP(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .mfaMethodNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be softwareTokenMFANotEnabled \(error)")
                return
            }
        }
    }

    /// Test a setUpTOTP call with resourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   resourceNotFoundException response
    /// - When:
    ///    - I invoke setUpTOTP with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testSetUpTOTPInWithResourceNotFoundException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                throw AssociateSoftwareTokenOutputError
                    .resourceNotFoundException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.setUpTOTP(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a setUpTOTP call with unknown response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   unknown response
    /// - When:
    ///    - I invoke setUpTOTP with a valid confirmation code
    /// - Then:
    ///    - I should get a .service
    ///
    func testSetUpWithUnknownException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { request in
                throw AssociateSoftwareTokenOutputError
                    .unknown(.init(httpResponse: .init(body: .empty, statusCode: .ok)))
            })

        do {
            let _ = try await plugin.setUpTOTP(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
        }
    }

}
