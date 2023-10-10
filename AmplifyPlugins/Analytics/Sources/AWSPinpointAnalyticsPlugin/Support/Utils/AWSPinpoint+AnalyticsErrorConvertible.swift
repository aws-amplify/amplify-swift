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

extension AWSPinpoint.BadRequestException: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        .unknown(properties.message ?? "", self)
    }
}

extension AWSPinpoint.ForbiddenException: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        .unknown(properties.message ?? "", self)
    }
}

extension AWSPinpoint.InternalServerErrorException: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        .unknown(properties.message ?? "", self)
    }
}

extension AWSPinpoint.MethodNotAllowedException: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        .unknown(properties.message ?? "", self)
    }
}

extension AWSPinpoint.NotFoundException: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        .unknown(properties.message ?? "", self)
    }
}

extension AWSPinpoint.PayloadTooLargeException: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        .unknown(properties.message ?? "", self)
    }
}

extension AWSPinpoint.TooManyRequestsException: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        .unknown(properties.message ?? "", self)
    }
}
