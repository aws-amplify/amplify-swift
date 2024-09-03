//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AwsCommonRuntimeKit
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint

extension CommonRunTimeError: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        switch self {
        case .crtError(let crtError):
            let errorDescription = isConnectivityError
            ? AWSPinpointErrorConstants.deviceOffline.errorDescription
            : crtError.message
            return .unknown(errorDescription, self)
        }
    }
}
