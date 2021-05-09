//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct AuthUserAttribute {

    /// <#Description#>
    public let key: AuthUserAttributeKey

    /// <#Description#>
    public let value: String

    /// <#Description#>
    /// - Parameters:
    ///   - key: <#key description#>
    ///   - value: <#value description#>
    public init(_ key: AuthUserAttributeKey, value: String) {
        self.key = key
        self.value = value
    }
}

/// <#Description#>
public enum AuthUserAttributeKey {
    // Attribute ref - https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-attributes.html
    case address

    /// <#Description#>
    case birthDate

    /// <#Description#>
    case email

    /// <#Description#>
    case familyName

    /// <#Description#>
    case gender

    /// <#Description#>
    case givenName

    /// <#Description#>
    case locale

    /// <#Description#>
    case middleName

    /// <#Description#>
    case name

    /// <#Description#>
    case nickname

    /// <#Description#>
    case phoneNumber

    /// <#Description#>
    case picture

    /// <#Description#>
    case preferredUsername

    /// <#Description#>
    case custom(String)

    /// <#Description#>
    case unknown(String)
}

extension AuthUserAttributeKey: Hashable {}
