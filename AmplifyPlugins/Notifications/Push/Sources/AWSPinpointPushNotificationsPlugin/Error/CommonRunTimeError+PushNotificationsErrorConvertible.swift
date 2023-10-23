//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AwsCommonRuntimeKit
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint

extension CommonRunTimeError: PushNotificationsErrorConvertible {
    var pushNotificationsError: PushNotificationsError {
        if isConnectivityError {
            return .network(
                PushNotificationsPluginErrorConstants.deviceOffline.errorDescription,
                PushNotificationsPluginErrorConstants.deviceOffline.recoverySuggestion,
                self
            )
        }

        switch self {
        case .crtError(let crtError):
            return .unknown(crtError.message, self)
        }
    }
}
