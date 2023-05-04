//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import AWSCognitoIdentityProvider
import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

class DeviceBehaviorFetchDevicesTests: BasePluginTest {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                try ListDevicesOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
    }

    /// Test fetchDevices operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchDevices operation
    /// - Then:
    ///    - I should get a successful task execution
    ///
    func testFetchDevicesRequest() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                ListDevicesOutputResponse(devices: [CognitoIdentityProviderClientTypes.DeviceType(deviceKey: "id")], paginationToken: nil)
            }
        )
        let options = AuthFetchDevicesRequest.Options()
        _ = try await plugin.fetchDevices(options: options)
    }

    /// Test fetchDevices operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchDevices operation
    /// - Then:
    ///    - I should get a successful task execution
    ///
    func testFetchDevicesRequestWithoutOptions() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                ListDevicesOutputResponse(devices: [CognitoIdentityProviderClientTypes.DeviceType(deviceKey: "id")], paginationToken: nil)
            }
        )
        _ = try await plugin.fetchDevices()
    }

    /// Test a successful fetchDevices call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a successful result with one device fetched
    ///
    func testSuccessfulListDevices() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                ListDevicesOutputResponse(devices: [CognitoIdentityProviderClientTypes.DeviceType(deviceKey: "id")], paginationToken: nil)
            }
        )
        let listDevicesResult = try await plugin.fetchDevices()
        guard listDevicesResult.count == 1 else {
            XCTFail("Result should have device count of 1")
            return
        }
    }

    /// Test a fetchDevices call with invalid response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a invalid response
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testListDevicesWithInvalidResult() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                ListDevicesOutputResponse(devices: nil, paginationToken: nil)
            }
        )
        do {
            let listDevicesResult = try await plugin.fetchDevices()
            XCTFail("Should not receive a success response \(listDevicesResult)")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should receive unknown error instead got \(error)")
                return
            }
        }
    }

    // MARK: - Service error for listDevices

    /// Test a fetchDevices with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response for fetchDevice
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testListDevicesWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw SdkError.service(
                    ListDevicesOutputError.internalErrorException(
                        .init()),
                    .init(body: .empty, statusCode: .accepted))
            }
        )
        do {
            let listDevicesResult = try await plugin.fetchDevices()
            XCTFail("Should not receive a success response \(listDevicesResult)")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error")
                return
            }
        }
    }

    /// Test a fetchDevices call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testListDevicesWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        do {
            _ = try await plugin.fetchDevices()
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

    /// Test a fetchDevices call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testListDevicesWithInvalidUserPoolConfigurationException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.invalidUserPoolConfigurationException(InvalidUserPoolConfigurationException(message: "invalid user pool configuration"))
            }
        )
        do {
            _ = try await plugin.fetchDevices()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should produce configuration error instead of \(error)")
                return
            }
        }
    }

    /// Test a fetchDevices call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testListDevicesWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        do {
            _ = try await plugin.fetchDevices()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a fetchDevices call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testListDevicesWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.passwordResetRequiredException(PasswordResetRequiredException(message: "password reset required"))
            }
        )
        do {
            _ = try await plugin.fetchDevices()
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

    /// Test a fetchDevices call with ResourceNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testListDevicesWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        do {
            _ = try await plugin.fetchDevices()
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

    /// Test a fetchDevices call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testListDevicesWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        do {
            _ = try await plugin.fetchDevices()
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

    /// Test a fetchDevices call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testListDevicesWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
        do {
            _ = try await plugin.fetchDevices()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
        }
    }

    /// Test a fetchDevices call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testListDevicesWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        do {
            _ = try await plugin.fetchDevices()
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
