//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
import AWSPinpoint
@testable import AWSPinpointPushNotificationsPlugin
import Foundation
import XCTest
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime

class ErrorPushNotificationsTests: XCTestCase {
    /// Given: A NSError error
    /// When: pushNotificationsError is invoked
    /// Then: An .unknown error is returned
    func testPushNotificationsError_withUnknownError_shouldReturnUnknownError() {
        let error = NSError(domain: "MyError", code: 1234)
        let pushNotificationsError = error.pushNotificationsError
        switch pushNotificationsError {
        case .unknown(let errorDescription, let underlyingError):
            XCTAssertEqual(errorDescription, "An unknown error occurred")
            XCTAssertEqual(error.localizedDescription, underlyingError?.localizedDescription)
        default:
            XCTFail("Expected error of type .unknown, got \(pushNotificationsError)")
        }
    }

    /// Given: A NSError error with a connectivity-related error code
    /// When: pushNotificationsError is invoked
    /// Then: A .network error is returned
    func testPushNotificationsError_withConnectivityError_shouldReturnNetworkError() {
        let error = NSError(domain: "ConnectivityError", code: NSURLErrorNotConnectedToInternet)
        let pushNotificationsError = error.pushNotificationsError
        switch pushNotificationsError {
        case .network(let errorDescription, let recoverySuggestion, let underlyingError):
            XCTAssertEqual(errorDescription, PushNotificationsPluginErrorConstants.deviceOffline.errorDescription)
            XCTAssertEqual(recoverySuggestion, PushNotificationsPluginErrorConstants.deviceOffline.recoverySuggestion)
            XCTAssertEqual(error.localizedDescription, underlyingError?.localizedDescription)
        default:
            XCTFail("Expected error of type .network, got \(pushNotificationsError)")
        }
    }

    /// Given: An Error defined by the SDK
    /// When: pushNotificationsError is invoked
    /// Then: A .service error is returned
    func testPushNotificationError_withServiceError_shouldReturnServiceError() {
        let errors: [(String, PushNotificationsErrorConvertible & Error)] = [
            ("BadRequestException", BadRequestException(message: "BadRequestException")),
            ("InternalServerErrorException", InternalServerErrorException(message: "InternalServerErrorException")),
            ("ForbiddenException", ForbiddenException(message: "ForbiddenException")),
            ("MethodNotAllowedException", MethodNotAllowedException(message: "MethodNotAllowedException")),
            ("NotFoundException", NotFoundException(message: "NotFoundException")),
            ("PayloadTooLargeException", PayloadTooLargeException(message: "PayloadTooLargeException")),
            ("TooManyRequestsException", TooManyRequestsException(message: "TooManyRequestsException"))
        ]

        for (expectedMessage, error) in errors {
            let pushNotificationsError = error.pushNotificationsError
            switch pushNotificationsError {
            case .service(let errorDescription, let recoverySuggestion, let underlyingError):
                XCTAssertEqual(errorDescription, expectedMessage)
                XCTAssertEqual(recoverySuggestion, PushNotificationsPluginErrorConstants.nonRetryableServiceError.recoverySuggestion)
                XCTAssertEqual(error.localizedDescription, underlyingError?.localizedDescription)
            default:
                XCTFail("Expected error of type .service, got \(pushNotificationsError)")
            }
        }
    }
}

#if canImport(AWSClientRuntime)
import AWSClientRuntime

extension ErrorPushNotificationsTests {

    /// Given: An UnknownAWSHTTPServiceError
    /// When: pushNotificationsError is invoked
    /// Then: A .unknown error is returned
    func testPushNotificationError_withUnknownAWSHTTPServiceError_shouldReturnUnknownError() {
        let error = UnknownAWSHTTPServiceError(
            httpResponse: .init(body: .empty, statusCode: .accepted), message: "UnknownAWSHTTPServiceError", requestID: nil, typeName: nil)
        let pushNotificationsError = error.pushNotificationsError
        switch pushNotificationsError {
        case .unknown(let errorDescription, let underlyingError):
            XCTAssertEqual(errorDescription, "UnknownAWSHTTPServiceError")
            XCTAssertEqual(error.localizedDescription, underlyingError?.localizedDescription)
        default:
            XCTFail("Expected error of type .unknown, got \(pushNotificationsError)")
        }
    }
}

#endif

#if canImport(AwsCommonRuntimeKit)
import AwsCommonRuntimeKit

extension ErrorPushNotificationsTests {

    /// Given: A CommonRunTimeError.crtError
    /// When: pushNotificationsError is invoked
    /// Then: A .unknown error is returned
    func testPushNotificationError_withCommonRunTimeError_shouldReturnUnknownError() {
        let error = CommonRunTimeError.crtError(.init(code: 12345))
        let pushNotificationsError = error.pushNotificationsError
        switch pushNotificationsError {
        case .unknown(let errorDescription, let underlyingError):
            XCTAssertEqual(errorDescription, "Unknown Error Code")
            XCTAssertEqual(error.localizedDescription, underlyingError?.localizedDescription)
        default:
            XCTFail("Expected error of type .unknown, got \(pushNotificationsError)")
        }
    }
}

#endif
