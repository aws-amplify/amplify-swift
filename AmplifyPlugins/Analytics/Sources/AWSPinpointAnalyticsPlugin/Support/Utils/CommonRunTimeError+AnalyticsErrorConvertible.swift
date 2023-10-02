//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
import AwsCommonRuntimeKit

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
