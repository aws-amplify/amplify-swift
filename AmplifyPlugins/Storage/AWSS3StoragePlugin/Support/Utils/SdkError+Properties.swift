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

extension SdkError {
    var httpResponse: HttpResponse? {
        switch self {
        case .service(_, let response):
            return response
        case .client(_, let response):
            return response
        default:
            return nil
        }
    }

    var statusCode: HttpStatusCode? {
        httpResponse?.statusCode
    }

    var clientError: ClientError? {
        switch self {
        case .client(let clientError, _):
            return clientError
        default:
            return nil
        }
    }

    var unknownError: Error? {
        switch self {
        case .unknown(let error):
            return error
        default:
            return nil
        }
    }

    var storageError: StorageError {
        let storageError: StorageError
        if let statusCode = statusCode?.rawValue,
           !(200..<299).contains(statusCode) {
            if [401, 403].contains(statusCode) {
                storageError = StorageError.accessDenied(localizedDescription, "", self)
            } else if statusCode == 404 {
                storageError = StorageError.keyNotFound(StorageError.serviceKey,
                                                        "Received HTTP Response status code 404 NotFound",
                                                        "Make sure the key exists before trying to download it.")
            } else {
                storageError = StorageError.httpStatusError(statusCode, localizedDescription)
            }
        } else if let clientError = clientError {
            storageError = StorageError.unknown(clientError.localizedDescription, clientError)
        } else {
            storageError = StorageError.unknown(localizedDescription, self)
        }

        return storageError
    }

}
