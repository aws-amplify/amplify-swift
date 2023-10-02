//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AwsCIo
import AwsCHttp
import AwsCommonRuntimeKit
import AWSPinpoint
import ClientRuntime
import Foundation

@_spi(InternalAWSPinpoint)
extension CommonRunTimeError {
    static let connectivityErrorCodes: Set<UInt32> = [
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

    public var isConnectivityError: Bool {
        switch self {
        case .crtError(let error):
            Self.connectivityErrorCodes.contains(UInt32(error.code))
        }
    }
}
