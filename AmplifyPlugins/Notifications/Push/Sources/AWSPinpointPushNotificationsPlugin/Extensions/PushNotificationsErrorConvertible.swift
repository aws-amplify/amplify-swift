//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify

protocol PushNotificationsErrorConvertible {
    var fallbackDescription: String { get }
    var pushNotificationsError: PushNotificationsError { get }
}

extension PushNotificationsErrorConvertible {
    var fallbackDescription: String { "" }
}

import AwsCommonRuntimeKit
import AwsCIo
import AwsCHttp

fileprivate let connectivityErrorCodes: Set<UInt32> = [
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

extension CommonRunTimeError: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        switch self {
        case .crtError(let error):
            return connectivityErrorCodes.contains(UInt32(error.code))
            ? .network(
                PushNotificationsPluginErrorConstants.deviceOffline.errorDescription,
                PushNotificationsPluginErrorConstants.deviceOffline.recoverySuggestion,
                self
            )
            : .unknown(error.message, error)
        }
    }
}

import AWSPinpoint
import AWSClientRuntime

extension AWSPinpoint.BadRequestException: PushNotificationsErrorConvertible {
    // TODO: Reasonable fallback description
    var fallbackDescription: String { "" }

    var pushNotificationsError: PushNotificationsError {
        .service(
            message ?? properties.message ?? "",
            "",
            self
        )
    }
}

extension AWSPinpoint.ForbiddenException: PushNotificationsErrorConvertible {
    // TODO: Reasonable fallback description
    var fallbackDescription: String { "" }

    var pushNotificationsError: PushNotificationsError {
        .service(
            message ?? properties.message ?? "",
            "",
            self
        )
    }
}

extension AWSPinpoint.InternalServerErrorException: PushNotificationsErrorConvertible {
    // TODO: Reasonable fallback description
    var fallbackDescription: String { "" }

    var pushNotificationsError: PushNotificationsError {
        .service(
            message ?? properties.message ?? "",
            "",
            self
        )
    }
}


extension AWSPinpoint.MethodNotAllowedException: PushNotificationsErrorConvertible {
    // TODO: Reasonable fallback description
    var fallbackDescription: String { "" }

    var pushNotificationsError: PushNotificationsError {
        .service(
            message ?? properties.message ?? "",
            "",
            self
        )
    }
}


extension AWSPinpoint.NotFoundException: PushNotificationsErrorConvertible {
    // TODO: Reasonable fallback description
    var fallbackDescription: String { "" }

    var pushNotificationsError: PushNotificationsError {
        .service(
            message ?? properties.message ?? "",
            "",
            self
        )
    }
}



extension AWSPinpoint.PayloadTooLargeException: PushNotificationsErrorConvertible {
    // TODO: Reasonable fallback description
    var fallbackDescription: String { "" }

    var pushNotificationsError: PushNotificationsError {
        .service(
            message ?? properties.message ?? "",
            "",
            self
        )
    }
}

extension AWSPinpoint.TooManyRequestsException: PushNotificationsErrorConvertible {
    // TODO: Reasonable fallback description
    var fallbackDescription: String { "" }

    var pushNotificationsError: PushNotificationsError {
        .service(
            message ?? properties.message ?? "",
            "",
            self
        )
    }
}

extension AWSClientRuntime.UnknownAWSHTTPServiceError: PushNotificationsErrorConvertible {
    // TODO: Reasonable fallback description
    var fallbackDescription: String { "" }

    var pushNotificationsError: PushNotificationsError {
        .service(
            message ?? "",
            "",
            self
        )
    }
}
