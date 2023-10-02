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
        switch self {
        case let error as PushNotificationsErrorConvertible:
            return error.pushNotificationsError
        default:
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
}
