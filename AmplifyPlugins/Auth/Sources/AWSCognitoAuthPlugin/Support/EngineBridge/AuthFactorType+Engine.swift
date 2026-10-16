//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAWSCognitoAuth

// Conversions between `Amplify.AuthFactorType` and the engine's `EngineAuthFactorType`.
// Case to case, never through `rawValue`, so neither side's string mapping can leak into the other.

extension EngineAuthFactorType {

    init(_ factor: AuthFactorType) {
        switch factor {
        case .password: self = .password
        case .passwordSRP: self = .passwordSRP
        case .smsOTP: self = .smsOTP
        case .emailOTP: self = .emailOTP
    #if os(iOS) || os(macOS) || os(visionOS)
        case .webAuthn:
            guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
                // A `.webAuthn` value only exists where the case is available.
                preconditionFailure("AuthFactorType.webAuthn outside its availability")
            }
            self = .webAuthn
    #endif
        }
    }
}

extension AuthFactorType {

    init(_ factor: EngineAuthFactorType) {
        switch factor {
        case .password: self = .password
        case .passwordSRP: self = .passwordSRP
        case .smsOTP: self = .smsOTP
        case .emailOTP: self = .emailOTP
    #if os(iOS) || os(macOS) || os(visionOS)
        case .webAuthn:
            guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
                // A `.webAuthn` value only exists where the case is available.
                preconditionFailure("EngineAuthFactorType.webAuthn outside its availability")
            }
            self = .webAuthn
    #endif
        }
    }
}
