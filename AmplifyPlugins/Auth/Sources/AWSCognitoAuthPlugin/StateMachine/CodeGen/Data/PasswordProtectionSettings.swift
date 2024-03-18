//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

@_spi(InternalAmplifyConfiguration)
public struct PasswordProtectionSettings: Equatable, Codable {
    public let minLength: UInt
    public let characterPolicy: [PasswordCharacterPolicy]

    public init(minLength: UInt,
                characterPolicy: [PasswordCharacterPolicy]) {
        self.minLength = minLength
        self.characterPolicy = characterPolicy
    }
}

@_spi(InternalAmplifyConfiguration)
public enum PasswordCharacterPolicy: String, Codable {
    case lowercase = "REQUIRES_LOWERCASE"
    case uppercase = "REQUIRES_UPPERCASE"
    case numbers = "REQUIRES_NUMBERS"
    case symbols = "REQUIRES_SYMBOLS"
}
