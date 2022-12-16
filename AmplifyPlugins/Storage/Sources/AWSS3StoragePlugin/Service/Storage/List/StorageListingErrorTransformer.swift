//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AWSS3
import ClientRuntime
import Foundation

/// Used to transform incoming errors to [StorageError](x-source-tag://StorageError) cases.
///
/// - Tag: StorageListingErrorTransformer
struct StorageListingErrorTransformer {
    
    var key: String?
    
    /// - Tag: StorageListingErrorTransformer.transform_sdkError
    func transform(sdkError: SdkError<ListObjectsV2OutputError>) -> StorageError {
        switch sdkError {
        case .unknown:
            return StorageError(error: sdkError)
        case .client(let clientError, let response):
            guard let response = response else {
                return transform(clientError: clientError)
            }
            if let result = transform(statusCode: response.statusCode.rawValue, error: sdkError) {
                return result
            }
        case .service(let error, let response):
            if let result = transform(statusCode: response.statusCode.rawValue, error: error) {
                return result
            }
        }
        return StorageError(error: sdkError)
    }
    
    /// - Tag: StorageListingErrorTransformer.transform_listClientError
    private func transform(clientError: ClientError) -> StorageError {
        switch clientError {
        case .authError(let message):
            return StorageError.authError(clientError.localizedDescription, message)
        case .crtError,
                .dataNotFound,
                .deserializationFailed,
                .networkError,
                .pathCreationFailed,
                .queryItemCreationFailed,
                .serializationFailed,
                .unknownError:
            return StorageError(error: clientError)
        case .retryError(let underlyingError):
            if let serviceError = underlyingError as? SdkError<ListObjectsV2OutputError> {
                return transform(sdkError: serviceError)
            }
            return StorageError(error: clientError)
        }
    }
    
    /// - Tag: StorageListingErrorTransformer.transform_statusCode
    private func transform(statusCode: Int, error: Error) -> StorageError? {
        let description = Self.errorDescription(forStatusCode: statusCode)
        switch statusCode {
        case 300...303, 305...399:
            // 300 range: Redirection
            return .httpStatusError(statusCode, "Redirection error", error)
        case 401, 403:
            // 400 range: Client Error
            return .accessDenied(
                description,
                "Make sure the user has access to the key before trying to download/upload it.",
                error
            )
        case 404:
            // 400 range: Client Error
            return .keyNotFound(
                key ?? "",
                description,
                "Make sure the key exists before trying to download it.",
                error
            )
        case 400...499:
            // 400 range: Client Error
            return .httpStatusError(statusCode, "Client error", error)
        case 500...599:
            // 500 range: Server Error
            return .httpStatusError(statusCode, "Server error", error)
        default:
            return nil
        }
    }
    
    /// - Tag: StorageListingErrorTransformer.errorDescription_forStatusCode
    private static func errorDescription(forStatusCode statusCode: Int) -> ErrorDescription {
        switch statusCode {
        case 401:
            return "Received HTTP Response status code \(statusCode) Unauthorized"
        case 403:
            return StorageErrorConstants.accessDenied.errorDescription
        case 404:
            return "Received HTTP Response status code \(statusCode) NotFound"
        default:
            return "Received HTTP Response status code \(statusCode)"
        }
    }
    
}

