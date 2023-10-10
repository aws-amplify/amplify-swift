//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AwsCommonRuntimeKit
import AwsCIo
import AwsCHttp

private let connectivityErrorCodes: Set<UInt32> = [
    AWS_ERROR_HTTP_CONNECTION_CLOSED.rawValue,
    AWS_ERROR_HTTP_SERVER_CLOSED.rawValue,
    AWS_IO_DNS_INVALID_NAME.rawValue,
    AWS_IO_DNS_NO_ADDRESS_FOR_HOST.rawValue,
    AWS_IO_DNS_QUERY_FAILED.rawValue,
    AWS_IO_SOCKET_CONNECT_ABORTED.rawValue,
    AWS_IO_SOCKET_CONNECTION_REFUSED.rawValue,
    AWS_IO_SOCKET_CLOSED.rawValue,
    AWS_IO_SOCKET_NETWORK_DOWN.rawValue,
    AWS_IO_SOCKET_NO_ROUTE_TO_HOST.rawValue,
    AWS_IO_SOCKET_NOT_CONNECTED.rawValue,
    AWS_IO_SOCKET_TIMEOUT.rawValue,
    AWS_IO_TLS_NEGOTIATION_TIMEOUT.rawValue,
    UInt32(AWS_HTTP_STATUS_CODE_408_REQUEST_TIMEOUT.rawValue)
]

extension CommonRunTimeError: AuthErrorConvertible {
    var authError: AuthError {
        let error: CRTError
        switch self { case .crtError(let crtError): error = crtError }

        if connectivityErrorCodes.contains(UInt32(error.code)) {
            return .service(error.name, error.message, AWSCognitoAuthError.network)
        } else {
            return .unknown("\(error.name) - \(error.message)", self)
        }
    }
}
