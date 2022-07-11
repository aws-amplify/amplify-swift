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

class UserBehaviorConfirmAttributeTests: BasePluginTest {

    /// Test a successful confirmUpdateUserAttributes call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulConfirmUpdateUserAttributes() {
        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            try VerifyUserAttributeOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: Service error handling test

    /// Test a confirmUpdateUserAttributes call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithCodeMismatchException() {
        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.codeMismatchException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .codeMismatch = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be codeMismatch \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with CodeExpiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeExpiredException response
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithExpiredCodeException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.expiredCodeException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .codeExpired = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be codeExpired \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testcConfirmUpdateUserAttributesWithInternalErrorException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.internalErrorException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce an unknown error instead of \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithInvalidParameterException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.invalidParameterException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be invalidParameter \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .limitExceeded error
    ///
    func testConfirmUpdateUserAttributesWithLimitExceededException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.limitExceededException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .limitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be limitExceeded \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testConfirmUpdateUserAttributesWithNotAuthorizedException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.notAuthorizedException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .notAuthorized = error else {
                    XCTFail("Should produce notAuthorized error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithPasswordResetRequiredException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.passwordResetRequiredException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be passwordResetRequired \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithResourceNotFoundException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.resourceNotFoundException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be resourceNotFound \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithTooManyRequestsException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.tooManyRequestsException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be requestLimitExceeded \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithUserNotConfirmedException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.userNotConfirmedException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
       _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be userNotConfirmed \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmUpdateUserAttributes call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testConfirmUpdateUserAttributesWithUserNotFoundException() {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.userNotFoundException(.init())
        })
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirm(userAttribute: .email, confirmationCode: "code") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be userNotFound \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}
