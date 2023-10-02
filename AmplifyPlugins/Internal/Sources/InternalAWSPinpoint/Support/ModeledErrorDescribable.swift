//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPinpoint

protocol ModeledErrorDescribable {
    var errorDescription: String { get }
}

extension AWSPinpoint.BadRequestException: ModeledErrorDescribable {
    var errorDescription: String { properties.message ?? "" }
}

extension AWSPinpoint.ForbiddenException: ModeledErrorDescribable {
    var errorDescription: String { properties.message ?? "" }
}

extension AWSPinpoint.InternalServerErrorException: ModeledErrorDescribable {
    var errorDescription: String { properties.message ?? "" }
}

extension AWSPinpoint.MethodNotAllowedException: ModeledErrorDescribable {
    var errorDescription: String { properties.message ?? "" }
}

extension AWSPinpoint.NotFoundException: ModeledErrorDescribable {
    var errorDescription: String { properties.message ?? "" }
}

extension AWSPinpoint.PayloadTooLargeException: ModeledErrorDescribable {
    var errorDescription: String { properties.message ?? "" }
}

extension AWSPinpoint.TooManyRequestsException: ModeledErrorDescribable {
    var errorDescription: String { properties.message ?? "" }
}
