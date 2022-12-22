//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import ClientRuntime
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint

extension SdkError {
    var analyticsError: AnalyticsError {
        return .unknown(
            isConnectivityError ? AWSPinpointErrorConstants.deviceOffline.errorDescription : errorDescription,
            rootError ?? self
        )
    }
}
