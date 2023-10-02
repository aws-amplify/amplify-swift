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
        switch self {
        case .crtError(let crtError):
            let errorDescription = isConnectivityError
            ? AWSPinpointErrorConstants.deviceOffline.errorDescription
            : crtError.message
            return .unknown(errorDescription, self)
        }
    }
}
