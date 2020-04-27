//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

// swiftlint:disable cyclomatic_complexity
extension AuthUserAttributeKey {

    func toString() -> String {
        switch self {
        case .address:
            return "address"
        case .birthDate:
            return "birthdate"
        case .email:
            return "email"
        case .familyName:
            return "family_name"
        case .gender:
            return "gender"
        case .givenName:
            return "given_name"
        case .locale:
            return "locale"
        case .middleName:
            return "middle_name"
        case .name:
            return "name"
        case .nickname:
            return "nickname"
        case .phoneNumber:
            return "phone_number"
        case .picture:
            return "picture"
        case .preferredUsername:
            return "preferred_username"
        case .custom(let attribute):
            return "custom: \(attribute)"
        }
    }
}
