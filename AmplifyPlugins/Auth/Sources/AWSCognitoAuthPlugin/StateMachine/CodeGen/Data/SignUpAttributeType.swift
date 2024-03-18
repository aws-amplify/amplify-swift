//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(InternalAmplifyConfiguration)
public enum SignUpAttributeType: String, Codable {
    case address = "ADDRESS"
    case birthDate = "BIRTHDATE"
    case email = "EMAIL"
    case familyName = "FAMILY_NAME"
    case gender = "GENDER"
    case givenName = "GIVEN_NAME"
    case middleName = "MIDDLE_NAME"
    case name = "NAME"
    case nickname = "NICKNAME"
    case phoneNumber = "PHONE_NUMBER"
    case preferredUsername = "PREFERRED_USERNAME"
    case profile = "PROFILE"
    case website = "WEBSITE"
}
