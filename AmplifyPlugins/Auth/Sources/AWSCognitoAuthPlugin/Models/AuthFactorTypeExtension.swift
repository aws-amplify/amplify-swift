//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthFactorType: DefaultLogger {

    internal init?(rawValue: String) {
        switch rawValue {
        case "PASSWORD": self = .password
        case "PASSWORD_SRP": self = .passwordSRP
        case "SMS_OTP": self = .smsOTP
        case "EMAIL_OTP": self = .emailOTP
        case "WEB_AUTHN":
        #if os(iOS) || os(macOS) || os(visionOS)
            if #available(iOS 17.4, macOS 13.5, *) {
                self = .webAuthn
            } else {
                Self.log.error("WEB_AUTHN is not supported in this OS version.")
                return nil
            }
        #else
            Self.log.error("WEB_AUTHN is only available in iOS and macOS.")
            return nil
        #endif
        default:
            Self.log.error("Tried to initialize an unsupported MFA type with value: \(rawValue)")
            return nil
        }
    }

    /// String value of Auth Factor Type
    public var rawValue: String {
        return challengeResponse
    }

    /// String value to be used as an input parameter  for confirmSignIn API
    public var challengeResponse: String {
        switch self {
        case .passwordSRP: return "PASSWORD_SRP"
        case .password: return "PASSWORD"
        case .smsOTP: return "SMS_OTP"
        case .emailOTP: return "EMAIL_OTP"
    #if os(iOS) || os(macOS) || os(visionOS)
        case .webAuthn: return "WEB_AUTHN"
    #endif
        }
    }
}
