//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSS3
import Amplify
import ClientRuntime
import XCTest

@testable import AWSS3StoragePlugin

final class StorageListingErrorTransformerTests: XCTestCase {
    
    /// Given: An `SdkError.client` containing a `ClientError.networkError` error without an associated HTTP response.
    /// When: The error is transformed to `StorageError`
    /// Then: An `StorageError.unknown` error is returned
    func testClientErrorMissingResponse() throws {
        let sut = StorageListingErrorTransformer(key: UUID().uuidString)
        let clientError = ClientError.networkError("Forbidden")
        let input = SdkError<ListObjectsV2OutputError>.client(clientError, nil)
        let output = sut.transform(sdkError: input)
        switch output {
        case .unknown:
            break
        default:
            XCTFail("Expecting unknown but got: \(output)")
        }
    }
    
    /// Given: An `SdkError.client` containing a `ClientError.authError` error **with** an associated HTTP response using a 403 status.
    /// When: The error is transformed to `StorageError`
    /// Then: An `StorageError.accessDenied` error is returned
    func testClientErrorWithResponse() throws {
        let sut = StorageListingErrorTransformer(key: UUID().uuidString)
        let response = HttpResponse(body: .empty, statusCode: .forbidden)
        let clientError = ClientError.authError("Forbidden")
        let input = SdkError<ListObjectsV2OutputError>.client(clientError, response)
        let output = sut.transform(sdkError: input)
        switch output {
        case .accessDenied:
            break
        default:
            XCTFail("Expecting accessDenied but got: \(output)")
        }
    }
    
    /// Given: An `SdkError.service` containing a `ClientError.retryError` which itself contains a nested `ListObjectsV2OutputError` error **with** an associated HTTP response using a 403 status.
    /// When: The error is transformed to `StorageError`
    /// Then: An `StorageError.accessDenied` error is returned
    func testClientErrorWithNestedRetriableError() throws {
        let sut = StorageListingErrorTransformer(key: UUID().uuidString)
        let response = HttpResponse(body: .empty, statusCode: .forbidden)
        let serviceError = try ListObjectsV2OutputError(errorType: UUID().uuidString, httpResponse: response)
        let retriableError = SdkError<ListObjectsV2OutputError>.service(serviceError, response)
        let clientError = ClientError.retryError(retriableError)
        let input = SdkError<ListObjectsV2OutputError>.client(clientError, nil)
        let output = sut.transform(sdkError: input)
        switch output {
        case .accessDenied:
            break
        default:
            XCTFail("Expecting accessDenied but got: \(output)")
        }
    }
    
    /// Given: An `SdkError.service` containing a `ListObjectsV2OutputError` error **with** an associated HTTP response using a 403 status.
    /// When: The error is transformed to `StorageError`
    /// Then: An `StorageError.accessDenied` error is returned
    func testServiceErrorPermissionDenied() throws {
        let sut = StorageListingErrorTransformer(key: UUID().uuidString)
        let response = HttpResponse(body: .empty, statusCode: .forbidden)
        let outputError = try ListObjectsV2OutputError(errorType: UUID().uuidString, httpResponse: response)
        let input = SdkError<ListObjectsV2OutputError>.service(outputError, response)
        let output = sut.transform(sdkError: input)
        switch output {
        case .accessDenied:
            break
        default:
            XCTFail("Expecting accessDenied but got: \(output)")
        }
    }
    
    /// Given: An `SdkError.service` containing a `ListObjectsV2OutputError` error **with** an associated HTTP response using a 404 status.
    /// When: The error is transformed to `StorageError`
    /// Then: An `StorageError.keyNotFound` error is returned
    func testServiceErrorNotFound() throws {
        let sut = StorageListingErrorTransformer(key: UUID().uuidString)
        let response = HttpResponse(body: .empty, statusCode: .notFound)
        let outputError = try ListObjectsV2OutputError(errorType: UUID().uuidString, httpResponse: response)
        let input = SdkError<ListObjectsV2OutputError>.service(outputError, response)
        let output = sut.transform(sdkError: input)
        switch output {
        case .keyNotFound:
            break
        default:
            XCTFail("Expecting accessDenied but got: \(output)")
        }
    }

    /// Given: An `SdkError.service` containing a `ListObjectsV2OutputError` error **with** an associated HTTP response using a 307 status.
    /// When: The error is transformed to `StorageError`
    /// Then: An `StorageError.httpStatusError` error is returned
    func testServiceErrorRedirect() throws {
        let sut = StorageListingErrorTransformer(key: UUID().uuidString)
        let response = HttpResponse(body: .empty, statusCode: .temporaryRedirect)
        let outputError = try ListObjectsV2OutputError(errorType: UUID().uuidString, httpResponse: response)
        let input = SdkError<ListObjectsV2OutputError>.service(outputError, response)
        let output = sut.transform(sdkError: input)
        switch output {
        case .httpStatusError:
            break
        default:
            XCTFail("Expecting httpStatusError but got: \(output)")
        }
    }
    
    /// Given: An `SdkError.service` containing a `ListObjectsV2OutputError` error **with** an associated HTTP response using a 500 status.
    /// When: The error is transformed to `StorageError`
    /// Then: An `StorageError.httpStatusError` error is returned
    func testServiceErrorInternalServerError() throws {
        let sut = StorageListingErrorTransformer(key: UUID().uuidString)
        let response = HttpResponse(body: .empty, statusCode: .internalServerError)
        let outputError = try ListObjectsV2OutputError(errorType: UUID().uuidString, httpResponse: response)
        let input = SdkError<ListObjectsV2OutputError>.service(outputError, response)
        let output = sut.transform(sdkError: input)
        switch output {
        case .httpStatusError:
            break
        default:
            XCTFail("Expecting httpStatusError but got: \(output)")
        }
    }
    
    /// Given: An `SdkError.unknown` containing an unexpected error.
    /// When: The error is transformed to `StorageError`
    /// Then: An `StorageError.unknown` error is returned
    func testUnknownError() throws {
        let sut = StorageListingErrorTransformer(key: UUID().uuidString)
        enum TestError: Error {
            case badbeef
        }
        let input = SdkError<ListObjectsV2OutputError>.unknown(TestError.badbeef)
        let output = sut.transform(sdkError: input)
        switch output {
        case .unknown:
            break
        default:
            XCTFail("Expecting unknown but got: \(output)")
        }
    }
}
