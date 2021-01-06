//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient

class UserBehaviorFetchAttributesTests: BaseUserBehaviorTest {

    /// Test a successful fetchUserAttributes call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulFetchUserAttributes() {

        mockAWSMobileClient?.getUserAttributeMockResult = .success(["email": "Amplify@amazon.com"])

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let attributes):
                XCTAssertEqual(attributes[0].key, AuthUserAttributeKey(rawValue: "email"))
                XCTAssertEqual(attributes[0].value, "Amplify@amazon.com")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a fetchUserAttributes call with invalid result
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock an invalid response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testFetchUserAttributesWithInvalidResult() {

        mockAWSMobileClient?.getUserAttributeMockResult = nil

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce an unknown error")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: Service error handling test

    /// Test a fetchUserAttributes call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testFetchUserAttributesWithInternalErrorException() {

        mockAWSMobileClient?.getUserAttributeMockResult =
            .failure(AWSMobileClientError.internalError(message: "Error"))

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
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

    /// Test a fetchUserAttributes call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InvalidParameterException response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    -  I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testFetchUserAttributesWithInvalidParameterException() {

        mockAWSMobileClient?.getUserAttributeMockResult =
            .failure(AWSMobileClientError.invalidParameter(message: "Error"))

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
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

    /// Test a fetchUserAttributes call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a NotAuthorizedException response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    -  I should get a .service error with  .notAuthorized as underlyingError
    ///
    func testFetchUserAttributesWithNotAuthorizedException() {

        mockAWSMobileClient?.getUserAttributeMockResult =
            .failure(AWSMobileClientError.notAuthorized(message: "Error"))

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
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

    /// Test a fetchUserAttributes call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testFetchUserAttributesWithPasswordResetRequiredException() {

        mockAWSMobileClient?.getUserAttributeMockResult =
            .failure(AWSMobileClientError.passwordResetRequired(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
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

    /// Test a fetchUserAttributes call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testFetchUserAttributesWithResourceNotFoundException() {

        mockAWSMobileClient?.getUserAttributeMockResult =
            .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
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
                    XCTFail("Underlying error should be passwordResetRequired \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a fetchUserAttributes call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testFetchUserAttributesWithTooManyRequestsException() {

        mockAWSMobileClient?.getUserAttributeMockResult =
            .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
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

    /// Test a fetchUserAttributes call with UserNotConfirmedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testFetchUserAttributesWithUserNotConfirmedException() {

        mockAWSMobileClient?.getUserAttributeMockResult =
            .failure(AWSMobileClientError.userNotConfirmed(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
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

    /// Test a fetchUserAttributes call with UserNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testFetchUserAttributesWithUserNotFoundException() {

        mockAWSMobileClient?.getUserAttributeMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchUserAttributes { result in
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
