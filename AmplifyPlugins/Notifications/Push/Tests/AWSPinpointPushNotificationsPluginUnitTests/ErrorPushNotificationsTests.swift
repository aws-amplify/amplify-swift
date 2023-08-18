//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
import AWSPinpoint
@testable import AWSPinpointPushNotificationsPlugin
import ClientRuntime
import Foundation
import XCTest

class ErrorPushNotificationsTests: XCTestCase {
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
   
    func testPushNotificationsError_withNetworkClientSdkError_shouldReturnNetworkError() throws {
        let error = NSError(domain: "ConnectivityError", code: NSURLErrorNotConnectedToInternet)
        let sdkError = SdkError<PutEventsOutputError>.client(.networkError(error), nil)
        let pushNotificationsError = sdkError.pushNotificationsError
        switch pushNotificationsError {
        case .network(let errorDescription, let recoverySuggestion, let underlyingError):
            XCTAssertEqual(errorDescription, PushNotificationsPluginErrorConstants.deviceOffline.errorDescription)
            XCTAssertEqual(recoverySuggestion, PushNotificationsPluginErrorConstants.deviceOffline.recoverySuggestion)
            XCTAssertEqual(error.localizedDescription, underlyingError?.localizedDescription)
        default:
            XCTFail("Expected error of type .network, got \(pushNotificationsError)")
        }
    }
    
    func testPushNotificationsError_withNetworkClientError_shouldReturnNetworkError() throws {
        let error = NSError(domain: "ConnectivityError", code: NSURLErrorNotConnectedToInternet)
        let clientError: Error = ClientError.networkError(error)
        let pushNotificationsError = clientError.pushNotificationsError
        switch pushNotificationsError {
        case .network(let errorDescription, let recoverySuggestion, let underlyingError):
            XCTAssertEqual(errorDescription, PushNotificationsPluginErrorConstants.deviceOffline.errorDescription)
            XCTAssertEqual(recoverySuggestion, PushNotificationsPluginErrorConstants.deviceOffline.recoverySuggestion)
            XCTAssertEqual(clientError.localizedDescription, underlyingError?.localizedDescription)
        default:
            XCTFail("Expected error of type .network, got \(pushNotificationsError)")
        }
    }

    func testPushNotificationsError_withUpdateEndpointSdkError_shouldReturnServiceError() throws {
        let httpResponse = ClientRuntime.HttpResponse(body: .none, statusCode: .notFound)
        let outputError = try UpdateEndpointOutputError(httpResponse: httpResponse)
        let error: Error = SdkError.service(outputError, httpResponse)
        let pushNotificationsError = error.pushNotificationsError
        switch pushNotificationsError {
        case .service(let errorDescription, let recoverySuggestion, let underlyingError):
            XCTAssertEqual(errorDescription, error.localizedDescription)
            XCTAssertEqual(recoverySuggestion, PushNotificationsPluginErrorConstants.nonRetryableServiceError.recoverySuggestion)
            XCTAssertEqual(error.localizedDescription, underlyingError?.localizedDescription)
        default:
            XCTFail("Expected error of type .service, got \(pushNotificationsError)")
        }
    }
    
    func testPushNotificationsError_withPutEventsSdkError_shouldReturnServiceError() throws {
        let httpResponse = ClientRuntime.HttpResponse(body: .none, statusCode: .notFound)
        let outputError = try PutEventsOutputError(httpResponse: httpResponse)
        let error: Error = SdkError.service(outputError, httpResponse)
        let pushNotificationsError = error.pushNotificationsError
        switch pushNotificationsError {
        case .service(let errorDescription, let recoverySuggestion, let underlyingError):
            XCTAssertEqual(errorDescription, error.localizedDescription)
            XCTAssertEqual(recoverySuggestion, PushNotificationsPluginErrorConstants.nonRetryableServiceError.recoverySuggestion)
            XCTAssertEqual(error.localizedDescription, underlyingError?.localizedDescription)
        default:
            XCTFail("Expected error of type .service, got \(pushNotificationsError)")
        }
    }
}
