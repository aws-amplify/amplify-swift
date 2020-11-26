//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient
import AWSCore
import AWSPluginsCore

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class AuthorizationProviderSessionSignoutTests: BaseAuthorizationProviderTest {

    override func setUp() {
        super.setUp()
        mockAWSMobileClient.mockCurrentUserState = .guest
    }

    /// Test signedOut session with unAuthenticated access enabled.
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = valid values
    ///         - identity id = valid values
    ///         - cognito tokens = .signedOut error
    ///
    func testSignoutSessionWithUnAuthAccess() {
        mockAWSCredentials()
        mockIdentityId()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):

                XCTAssertFalse(session.isSignedIn)

                let creds = try? (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().get()
                XCTAssertNotNil(creds?.accessKey)
                XCTAssertNotNil(creds?.secretKey)

                let identityId = try? (session as? AuthCognitoIdentityProvider)?.getIdentityId().get()
                XCTAssertNotNil(identityId)

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }

            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with unAuthenticated access disabled.
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access disabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock disabled guest in service
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .service error with .invalidAccountTypeException as underlying error
    ///         - identity id = .service error with .invalidAccountTypeException as underlying error
    ///         - cognito tokens = .signedOut error
    func testSignoutSessionWithUnAuthAccessDisabled() {
        mockIdentityId()
        let mockNoGuestError = AWSMobileClientError.guestAccessNotAllowed(message: "Error")
        mockAWSMobileClient.awsCredentialsMockResult = .failure(mockNoGuestError)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .service(_, _, let underlyingError) = credentialsError,
                      case .invalidAccountTypeException = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should return service error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .service(_, _, let identityIdUnderlyingError) = identityIdError,
                      case .invalidAccountTypeException = (identityIdUnderlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should return service error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }

            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with identity id not available
    ///
    /// - Given: Given an auth plugin with signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession and mock identity id unavailable error
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .service error
    ///         - identity id = .service error
    ///         - cognito tokens = .signedOut error
    func testSignoutSessionWithIdentityIdUnAvailable() {

        let mockIdentityIdUnAvailError = AWSMobileClientError.identityIdUnavailable(message: "Error")
        mockAWSMobileClient.awsCredentialsMockResult = .failure(mockIdentityIdUnAvailError)
        mockAWSMobileClient.getIdentityIdMockResult = AWSTask(error: mockIdentityIdUnAvailError)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .service(_, _, let underlyingError) = credentialsError else {
                    XCTFail("Should return service error")
                    return
                }
                XCTAssertNil(underlyingError, "No underlying error is returned")

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .service(_, _, let identityIdUnderlyingError) = identityIdError else {
                    XCTFail("Should return service error")
                    return
                }

                XCTAssertNil(identityIdUnderlyingError, "No underlying error is returned")
                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }

            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a invalid response for AWS Credentials
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock invalid response for aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testInvalidCredentialsResponseInSignedOut() {
        mockIdentityId()
        mockAWSMobileClient.awsCredentialsMockResult = nil

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a invalid response for AWS Credentials
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock invalid response for identity id
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testInvalidIdentityIdResponseInSignedOut() {
        mockAWSCredentials()
        mockAWSMobileClient.getIdentityIdMockResult = AWSTask(result: nil)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a network error
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock URL domain error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .service error with .network as underlying error
    ///         - identity id = .service error with .network as underlying error
    ///         - cognito tokens = .signedOut error
    func testNetworkErrorForIdentityIdInSignedOut() {
        mockAWSCredentials()
        let error = NSError(domain: NSURLErrorDomain, code: 1, userInfo: nil)
        mockAWSMobileClient.getIdentityIdMockResult = AWSTask(error: error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .service(_, _, let underlyingError) = credentialsError,
                      case .network = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should return network error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .service(_, _, let identityIdUnderlyingError) = identityIdError,
                      case .network = (identityIdUnderlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should return network error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a network error
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock URL domain error for getIdentityId
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .service error with .network as underlying error
    ///         - identity id = .service error with .network as underlying error
    ///         - cognito tokens = .signedOut error
    func testNetworkErrorForAWSCredentialsInSignedOut() {
        mockIdentityId()
        let error = NSError(domain: NSURLErrorDomain, code: 1, userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .service(_, _, let underlyingError) = credentialsError,
                      case .network = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should return network error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .service(_, _, let identityIdUnderlyingError) = identityIdError,
                      case .network = (identityIdUnderlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should return network error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service Error for GetId

    /// Test signedOut session with a service error in identity id. Currently AWSMobileClient converts all
    /// service error in getID api to `AWSCognitoCredentialsProviderHelperErrorTypeIdentityIsNil` of domain
    /// `AWSCognitoCredentialsProviderHelperErrorDomain`
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock any service error for  getId
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testNilIdentityIdErrorInSignedOut() {
        mockAWSCredentials()
        let error = NSError(domain: AWSCognitoCredentialsProviderHelperErrorDomain,
                            code: AWSCognitoCredentialsProviderHelperErrorType.identityIsNil.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.getIdentityIdMockResult = AWSTask(error: error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service Error for GetCredentialsForIdentity

    /// Test signedOut session with a `ExternalServiceException` service error in aws credential call
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock ExternalServiceException error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testSignedOutSessionWithAWSCredentialsExternalServiceException() {
        mockIdentityId()
        let error = NSError(domain: AWSCognitoIdentityErrorDomain,
                            code: AWSCognitoIdentityErrorType.externalService.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a `InternalErrorException` service error in aws credential call
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock InternalErrorException error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testSignedOutSessionWithAWSCredentialsInternalErrorException() {
        mockIdentityId()
        let error = NSError(domain: AWSCognitoIdentityErrorDomain,
                            code: AWSCognitoIdentityErrorType.internalError.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a `InvalidIdentityPoolConfigurationException` service error in aws credential call
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock InvalidIdentityPoolConfigurationException error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testSignedOutSessionWithAWSCredentialsInvalidIdentityPoolConfigurationException() {
        mockAWSCredentials()
        let error = NSError(domain: AWSCognitoIdentityErrorDomain,
                            code: AWSCognitoIdentityErrorType.invalidIdentityPoolConfiguration.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a `InvalidParameterException` service error in aws credential call
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock InvalidParameterException error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testSignedOutSessionWithAWSCredentialsInvalidParameterException() {
        mockIdentityId()
        let error = NSError(domain: AWSCognitoIdentityErrorDomain,
                            code: AWSCognitoIdentityErrorType.invalidParameter.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a `NotAuthorizedException` service error in aws credential call
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock NotAuthorizedException error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testSignedOutSessionWithAWSCredentialsNotAuthorizedException() {
        mockIdentityId()
        let error = NSError(domain: AWSCognitoIdentityErrorDomain,
                            code: AWSCognitoIdentityErrorType.notAuthorized.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a `ResourceConflictException` service error in aws credential call
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock ResourceConflictException error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testSignedOutSessionWithAWSCredentialsResourceConflictException() {
        mockIdentityId()
        let error = NSError(domain: AWSCognitoIdentityErrorDomain,
                            code: AWSCognitoIdentityErrorType.resourceConflict.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a `ResourceNotFoundException` service error in aws credential call
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock ResourceNotFoundException error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testSignedOutSessionWithAWSCredentialsResourceNotFoundException() {
        mockIdentityId()
        let error = NSError(domain: AWSCognitoIdentityErrorDomain,
                            code: AWSCognitoIdentityErrorType.resourceNotFound.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedOut session with a `TooManyRequestsException` service error in aws credential call
    ///
    /// - Given: Given an auth plugin with signedOut state and unauthenticated access enabled in backend
    /// - When:
    ///    - I invoke fetchAuthSession and mock TooManyRequestsException error for get aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = false
    ///         - aws credentails = .unknown error
    ///         - identity id = .unknown error
    ///         - cognito tokens = .signedOut error
    func testSignedOutSessionWithAWSCredentialsTooManyRequestsException() {
        mockIdentityId()
        let error = NSError(domain: AWSCognitoIdentityErrorDomain,
                            code: AWSCognitoIdentityErrorType.tooManyRequests.rawValue,
                            userInfo: nil)
        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertFalse(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let credentialsError) = credentialsResult,
                      case .unknown = credentialsError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let error) = tokensResult,
                      case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}
