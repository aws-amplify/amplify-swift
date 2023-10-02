//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPinpoint
import ClientRuntime
import AWSClientRuntime

private func recoverySuggestion(for error: ClientRuntime.ModeledError) -> String {
    type(of: error).isRetryable
    ? PushNotificationsPluginErrorConstants.retryableServiceError.recoverySuggestion
    : PushNotificationsPluginErrorConstants.nonRetryableServiceError.recoverySuggestion
}

extension AWSPinpoint.BadRequestException: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        .service(
            properties.message ?? "",
            recoverySuggestion(for: self),
            self
        )
    }
}

extension AWSPinpoint.ForbiddenException: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        .service(
            properties.message ?? "",
            recoverySuggestion(for: self),
            self
        )
    }
}

extension AWSPinpoint.InternalServerErrorException: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        .service(
            properties.message ?? "",
            recoverySuggestion(for: self),
            self
        )
    }
}

extension AWSPinpoint.MethodNotAllowedException: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        .service(
            properties.message ?? "",
            recoverySuggestion(for: self),
            self
        )
    }
}

extension AWSPinpoint.NotFoundException: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        .service(
            properties.message ?? "",
            recoverySuggestion(for: self),
            self
        )
    }
}

extension AWSPinpoint.PayloadTooLargeException: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        .service(
            properties.message ?? "",
            recoverySuggestion(for: self),
            self
        )
    }
}

extension AWSPinpoint.TooManyRequestsException: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        .service(
            properties.message ?? "",
            recoverySuggestion(for: self),
            self
        )
    }
}

extension AWSClientRuntime.UnknownAWSHTTPServiceError: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        .unknown(
            message ?? "An unknown error has occurred.",
            self
        )
    }
}
