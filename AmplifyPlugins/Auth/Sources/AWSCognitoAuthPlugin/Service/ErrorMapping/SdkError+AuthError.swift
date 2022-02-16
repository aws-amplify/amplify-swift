//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import ClientRuntime

extension SdkError: AuthErrorConvertible {

    var authError: AuthError {
        switch self {

        case .service(let serviceError, _):
            if let authErrorMappable = serviceError as? AuthErrorConvertible {
                return authErrorMappable.authError
            } else if let otherError = serviceError as? Error {
                return AuthError.service(otherError.localizedDescription, "", otherError)
            } else {
                return AuthError.unknown(String(describing: serviceError))
            }
        case .client(let clientError, let httpResponse):
            return convertToAuthError(clientError: clientError, httpResponse: httpResponse)
        case .unknown(let unknownError):
            return AuthError.unknown("An unknown error occured, check the underlying error for more details",
                                     unknownError)
        }
    }

    func convertToAuthError(clientError: ClientError,
                            httpResponse: HttpResponse? = nil) -> AuthError
    {
        switch clientError {
        case .networkError(let error):
            return AuthError.service(error.localizedDescription,
                                     """
                                    Check your network connection, retry when the network is available.
                                    HTTP Response stauts code: \(String(describing: httpResponse?.statusCode))
                                    """,
                                     AWSCognitoAuthError.network)

        case .crtError(let cRTError):
            return AuthError.service(cRTError.localizedDescription,
                                     "Check the underlying error for more details",
                                     cRTError)

        case .pathCreationFailed(let message):
            return AuthError.service(message, "", clientError)

        case .serializationFailed(let message):
            return AuthError.service(message, "", clientError)

        case .deserializationFailed(let error):
            return AuthError.service(error.localizedDescription,
                                     "",
                                     error)

        case .dataNotFound(let message):
            return AuthError.service(message, "", clientError)

        case .authError(let message):
            return AuthError.notAuthorized(message, "Check if you are authorized to perform the request")

        case .retryError(let error):
            return AuthError.service(error.localizedDescription,
                                     "",
                                     AWSCognitoAuthError.network)

        case .unknownError(let message):
            return AuthError.unknown(message, clientError)
        }
    }

}
