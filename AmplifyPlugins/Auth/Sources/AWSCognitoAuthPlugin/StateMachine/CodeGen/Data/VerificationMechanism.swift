//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(InternalAmplifyConfiguration)
public enum VerificationMechanism: String, Codable {
    case email = "EMAIL"
    case phoneNumber = "PHONE_NUMBER"
}
