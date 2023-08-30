//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import AWSS3
import ClientRuntime
import AWSClientRuntime

extension StorageError {
    static var serviceKey: String {
        "s3"
    }
}

//extension SdkError {
//    var httpResponse: HttpResponse? {
//        switch self {
//        case .service(_, let response):
//            return response
//        case .client(_, let response):
//            return response
//        default:
//            return nil
//        }
//    }
//
//    var statusCode: HttpStatusCode? {
//        if let statusCode = httpResponse?.statusCode {
//            return statusCode
//        }
//
//        guard case let .retryError(error) = clientError,
//           let sdkError = error as? Self else {
//            return nil
//        }
//
//        return sdkError.statusCode
//    }
//
//    var clientError: ClientError? {
//        switch self {
//        case .client(let clientError, _):
//            return clientError
//        default:
//            return nil
//        }
//    }
//
//    var unknownError: Error? {
//        switch self {
//        case .unknown(let error):
//            return error
//        default:
//            return nil
//        }
//    }
//
//    func isOk(statusCode: Int) -> Bool {
//        (200..<299).contains(statusCode)
//    }
//
//    func isAccessDenied(statusCode: Int) -> Bool {
//        [401, 403].contains(statusCode)
//    }
//
//    func isNotFound(statusCode: Int) -> Bool {
//        404 == statusCode
//    }
//
//    var storageError: StorageError {
//        let storageError: StorageError
//        if let statusCode = statusCode?.rawValue,
//           !isOk(statusCode: statusCode) {
//            if isAccessDenied(statusCode: statusCode) {
//                storageError = StorageError.accessDenied(StorageErrorConstants.accessDenied.errorDescription,
//                                                         StorageErrorConstants.accessDenied.recoverySuggestion,
//                                                         self)
//            } else if isNotFound(statusCode: statusCode) {
//                storageError = StorageError.keyNotFound(StorageError.serviceKey,
//                                                        "Received HTTP Response status code 404 NotFound",
//                                                        "Make sure the key exists before trying to download it.")
//            } else {
//                storageError = StorageError.httpStatusError(statusCode, localizedDescription, self)
//            }
//        } else if let clientError = clientError {
//            storageError = StorageError.unknown(clientError.localizedDescription, clientError)
//        } else {
//            storageError = StorageError.unknown(localizedDescription, self)
//        }
//
//        return storageError
//    }
//
//}
