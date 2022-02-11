//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

// swiftlint:disable cyclomatic_complexity
extension AuthUserAttributeKey: RawRepresentable {

    public typealias RawValue = String

    // Values are taken from:
    // https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-attributes.html
    private static let addressRawValue = "address"
    private static let birthDateRawValue = "birthdate"
    private static let emailRawValue = "email"
    private static let familyNameRawValue = "family_name"
    private static let genderRawValue = "gender"
    private static let givenNameRawValue = "given_name"
    private static let localeRawValue = "locale"
    private static let middleNameRawValue = "middle_name"
    private static let nameRawValue = "name"
    private static let nicknameRawValue = "nickname"
    private static let phoneNumberRawValue = "phone_number"
    private static let pictureRawValue = "picture"
    private static let preferredUsernameRawValue = "preferred_username"
    private static let customAttributePrefix = "custom:"

    public init(rawValue: String) {
        switch rawValue {
        case AuthUserAttributeKey.addressRawValue:
            self = .address
        case AuthUserAttributeKey.birthDateRawValue:
            self = .birthDate
        case AuthUserAttributeKey.emailRawValue:
            self = .email
        case AuthUserAttributeKey.familyNameRawValue:
            self = .familyName
        case AuthUserAttributeKey.genderRawValue:
            self = .gender
        case AuthUserAttributeKey.givenNameRawValue:
            self = .givenName
        case AuthUserAttributeKey.localeRawValue:
            self = .locale
        case AuthUserAttributeKey.middleNameRawValue:
            self = .middleName
        case AuthUserAttributeKey.nameRawValue:
            self = .name
        case AuthUserAttributeKey.nicknameRawValue:
            self = .nickname
        case AuthUserAttributeKey.phoneNumberRawValue:
            self = .phoneNumber
        case AuthUserAttributeKey.pictureRawValue:
            self = .picture
        case AuthUserAttributeKey.preferredUsernameRawValue:
            self = .preferredUsername
        default:
            if rawValue.starts(with: AuthUserAttributeKey.customAttributePrefix) {
                let attribute = String(rawValue.dropFirst(AuthUserAttributeKey.customAttributePrefix.count))
                self = .custom(attribute)
            } else {
                self = .unknown(rawValue)
            }
        }
    }

    public var rawValue: String {
        switch self {
        case .address:
            return AuthUserAttributeKey.addressRawValue
        case .birthDate:
            return AuthUserAttributeKey.birthDateRawValue
        case .email:
            return AuthUserAttributeKey.emailRawValue
        case .familyName:
            return AuthUserAttributeKey.familyNameRawValue
        case .gender:
            return AuthUserAttributeKey.genderRawValue
        case .givenName:
            return AuthUserAttributeKey.givenNameRawValue
        case .locale:
            return AuthUserAttributeKey.localeRawValue
        case .middleName:
            return AuthUserAttributeKey.middleNameRawValue
        case .name:
            return AuthUserAttributeKey.nameRawValue
        case .nickname:
            return AuthUserAttributeKey.nicknameRawValue
        case .phoneNumber:
            return AuthUserAttributeKey.phoneNumberRawValue
        case .picture:
            return AuthUserAttributeKey.pictureRawValue
        case .preferredUsername:
            return AuthUserAttributeKey.preferredUsernameRawValue
        case .custom(let attribute):
            return AuthUserAttributeKey.customAttributePrefix + attribute
        case .unknown(let rawValue):
            return rawValue
        }
    }
}
