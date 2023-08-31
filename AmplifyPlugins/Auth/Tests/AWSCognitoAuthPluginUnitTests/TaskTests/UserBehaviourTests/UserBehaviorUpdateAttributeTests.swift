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
import ClientRuntime
import AWSClientRuntime

class UserBehaviorUpdateAttributesTests: BasePluginTest {

    /// Test a successful updateUserAttributes call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfulUpdateUserAttributes() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            UpdateUserAttributesOutputResponse(codeDeliveryDetailsList: [
                .init(attributeName: "attributeName",
                      deliveryMedium: .email,
                      destination: "destination")])
        })

        let attributes = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
        guard case .done = attributes.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
    }

    /// Test a updateUserAttributes call with empty code delivery result
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock an empty response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should NOT get an error
    ///
    func testUpdateUserAttributesWithEmptyResult() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            UpdateUserAttributesOutputResponse()
        })
        _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
    }

    // MARK: Service error handling test

    /// Test a updateUserAttributes call with aliasExistsException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   aliasExistsException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .aliasExists as underlyingError
    ///
    func testUpdateUserAttributesWithAliasExistsException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw try await AWSCognitoIdentityProvider.AliasExistsException(
                httpResponse: .init(body: .empty, statusCode: .accepted),
                decoder: nil,
                message: nil,
                requestID: nil
            )
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .aliasExists = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be aliasExists \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with CodeDeliveryFailureException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .codeDelivery as underlyingError
    ///
    func testUpdateUserAttributesWithCodeDeliveryFailureException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.CodeDeliveryFailureException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeDelivery = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeDelivery \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testUpdateUserAttributesWithCodeMismatchException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.CodeMismatchException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeMismatch = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeMismatch \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with CodeExpiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeExpiredException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testUpdateUserAttributesWithExpiredCodeException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.ExpiredCodeException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeExpired = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeExpired \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testUpdateUserAttributesWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw try await AWSClientRuntime.UnknownAWSHTTPServiceError(
                httpResponse: .init(body: .empty, statusCode: .ok),
                message: nil,
                requestID: nil,
                requestID2: nil,
                typeName: nil
            )
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with InvalidEmailRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a --
    ///
    func testUpdateUserAttributesWithInvalidEmailRoleAccessPolicyException() async throws {
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidEmailRoleAccessPolicyException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .emailRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be email role \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with InvalidLambdaResponseException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testUpdateUserAttributesWithInvalidLambdaResponseException() async throws {
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidLambdaResponseException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testUpdateUserAttributesWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidParameterException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
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

    /// Test a updateUserAttributes call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a --
    ///
    func testUpdateUserAttributesWithinvalidSmsRoleAccessPolicyException() async throws {
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidSmsRoleAccessPolicyException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be sms exists \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with InvalidSmsRoleTrustRelationship response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a --
    ///
    func testUpdateUserAttributesCodeWithInvalidSmsRoleTrustRelationshipException() async throws {
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidSmsRoleTrustRelationshipException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be sms role \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testUpdateUserAttributesWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.NotAuthorizedException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testUpdateUserAttributesWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.PasswordResetRequiredException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be passwordResetRequired \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testUpdateUserAttributesWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.ResourceNotFoundException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be resourceNotFound \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testUpdateUserAttributesWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.TooManyRequestsException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be requestLimitExceeded \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with UnexpectedLambdaException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testUpdateUserAttributesWithUnexpectedLambdaException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.UnexpectedLambdaException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with UserLambdaValidationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testUpdateUserAttributesWithUserLambdaValidationException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.UserLambdaValidationException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testUpdateUserAttributesWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.UserNotConfirmedException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotConfirmed \(error)")
                return
            }
        }
    }

    /// Test a updateUserAttributes call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testUpdateUserAttributesWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw AWSCognitoIdentityProvider.UserNotFoundException()
        })
        do {
            _ = try await plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com"))
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
        }
    }

}
