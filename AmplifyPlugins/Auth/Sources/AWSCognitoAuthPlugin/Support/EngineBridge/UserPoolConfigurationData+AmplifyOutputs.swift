//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAWSCognitoAuth

// The `AmplifyOutputsData` initializers of the engine's configuration types. The engine never
// parses configuration; `ConfigurationHelper` builds engine values through these. They are plugin-side, so
// they are extensions on a type from another module: the struct
// initializer delegates to the type's `package` init, and the raw-value enums assign `self`.

extension UserPoolConfigurationData.PasswordProtectionSettings {
    init(from passwordPolicy: AmplifyOutputsData.Auth.PasswordPolicy) {
        var characterPolicy = [UserPoolConfigurationData.PasswordCharacterPolicy]()
        if passwordPolicy.requireLowercase {
            characterPolicy.append(.lowercase)
        }
        if passwordPolicy.requireUppercase {
            characterPolicy.append(.uppercase)
        }
        if passwordPolicy.requireNumbers {
            characterPolicy.append(.numbers)
        }
        if passwordPolicy.requireSymbols {
            characterPolicy.append(.symbols)
        }

        self.init(minLength: passwordPolicy.minLength, characterPolicy: characterPolicy)
    }
}

extension UserPoolConfigurationData.UsernameAttribute {
    init(from attribute: AmplifyOutputsData.Auth.UsernameAttributes) {
        switch attribute {
        case .email:
            self = .email
        case .phoneNumber:
            self = .phoneNumber
        }
    }
}

extension UserPoolConfigurationData.SignUpAttributeType {
    /// The sign-up attribute whose raw value is the outputs attribute's name in upper case (`family_name` is
    /// `FAMILY_NAME`), or `nil` for the standard attributes the Authenticator does not offer at sign-up:
    /// `locale`, `picture`, `sub`, `updated_at` and `zoneinfo`.
    /// `UserPoolConfigurationDataAmplifyOutputsTests` pins the mapping for every standard attribute.
    init?(from attribute: AmplifyOutputsData.AmazonCognitoStandardAttributes) {
        self.init(rawValue: attribute.rawValue.uppercased())
    }
}

extension UserPoolConfigurationData.VerificationMechanism {
    init(from attribute: AmplifyOutputsData.Auth.UserVerificationType) {
        switch attribute {
        case .email:
            self = .email
        case .phoneNumber:
            self = .phoneNumber
        }
    }
}
