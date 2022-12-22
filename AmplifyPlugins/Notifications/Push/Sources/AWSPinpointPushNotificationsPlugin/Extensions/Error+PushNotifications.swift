//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import ClientRuntime
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint

extension Error {
    var pushNotificationsError: PushNotificationsError {
        if let sdkError = self as? SdkError<UpdateEndpointOutputError> {
            return sdkError.pushNotificationsError
        }

        if let sdkError = self as? SdkError<PutEventsOutputError> {
            return sdkError.pushNotificationsError
        }

        if let clientError = self as? ClientError,
           case .networkError(_) = clientError {
            return .network(
                PushNotificationsPluginErrorConstants.deviceOffline.errorDescription,
                PushNotificationsPluginErrorConstants.deviceOffline.recoverySuggestion,
                clientError
            )
        }

        let networkErrorCodes = [
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorNotConnectedToInternet
        ]
        if networkErrorCodes.contains(where: { $0 == (self as NSError).code }) {
            return .network(
                PushNotificationsPluginErrorConstants.deviceOffline.errorDescription,
                PushNotificationsPluginErrorConstants.deviceOffline.recoverySuggestion,
                self
            )
        }

        return PushNotificationsError(error: self)
    }
}

extension SdkError {
    var pushNotificationsError: PushNotificationsError {
        if isConnectivityError {
            return .network(
                PushNotificationsPluginErrorConstants.deviceOffline.errorDescription,
                PushNotificationsPluginErrorConstants.deviceOffline.recoverySuggestion,
                rootError ?? self
            )
        }

        let recoverySuggestion = isRetryable ?
            PushNotificationsPluginErrorConstants.retryableServiceError.recoverySuggestion :
            PushNotificationsPluginErrorConstants.nonRetryableServiceError.recoverySuggestion

        return .service(
            errorDescription,
            recoverySuggestion,
            rootError ?? self
        )
    }
}
