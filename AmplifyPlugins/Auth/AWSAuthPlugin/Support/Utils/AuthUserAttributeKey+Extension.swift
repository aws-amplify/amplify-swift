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

extension String {

    func toUserAttributeKey() -> AuthUserAttributeKey {
        switch self {
        case AuthUserAttributeKey.address.toString():
            return .address
        case AuthUserAttributeKey.birthDate.toString():
            return .birthDate
        case AuthUserAttributeKey.email.toString():
            return .email
        case AuthUserAttributeKey.familyName.toString():
            return .familyName
        case AuthUserAttributeKey.gender.toString():
            return .gender
        case AuthUserAttributeKey.givenName.toString():
            return .givenName
        case AuthUserAttributeKey.locale.toString():
            return .locale
        case AuthUserAttributeKey.middleName.toString():
            return .middleName
        case AuthUserAttributeKey.name.toString():
            return .name
        case AuthUserAttributeKey.nickname.toString():
            return .nickname
        case AuthUserAttributeKey.phoneNumber.toString():
            return .phoneNumber
        case AuthUserAttributeKey.picture.toString():
            return .picture
        case AuthUserAttributeKey.preferredUsername.toString():
            return .preferredUsername
        default:
            return .custom(self)
        }

    }
}
