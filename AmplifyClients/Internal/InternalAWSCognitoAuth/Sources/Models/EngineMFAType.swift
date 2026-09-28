//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// The engine's copy of `Amplify.MFAType`, with the plugin's `MFATypeExtension.swift` members
/// (`init?(rawValue:)`, `rawValue`, `challengeResponse`) copied onto it.
///
/// `rawValue` is the Cognito name (`"SMS_MFA"`, ...), as the plugin extension shadows it, not Amplify's own
/// `String` raw value (`"sms"`). Case names and the log message match the public type exactly. The plugin
/// converts case to case in `AWSCognitoAuthPlugin/Support/EngineBridge/MFAType+Engine.swift`.
package enum EngineMFAType {

    /// Short Messaging Service linked with a phone number
    case sms

    /// Time-based One Time Password linked with an authenticator app
    case totp

    /// Email Service linked with an email
    case email
}

extension EngineMFAType: Sendable { }

package extension EngineMFAType {

    /// A static site (no environment in scope), so it logs through the global router. The category is
    /// the public type's `DefaultLogger` category, written as a literal so the fork's name never shows.
    private static var log: EngineLogger {
        EngineLog.logger(.category("MFAType"))
    }

    init?(rawValue: String) {
        if rawValue.caseInsensitiveCompare("SMS_MFA") == .orderedSame {
            self = .sms
        } else if rawValue.caseInsensitiveCompare("SOFTWARE_TOKEN_MFA") == .orderedSame {
            self = .totp
        } else if rawValue.caseInsensitiveCompare("EMAIL_OTP") == .orderedSame {
            self = .email
        } else {
            Self.log.error("Tried to initialize an unsupported MFA type with value: \(rawValue)")
            return nil
        }
    }

    /// String value of MFA Type
    var rawValue: String {
        return challengeResponse
    }

    /// String value to be used as an input parameter during MFA selection for confirmSignIn API
    var challengeResponse: String {
        switch self {
        case .sms:
            return "SMS_MFA"
        case .totp:
            return "SOFTWARE_TOKEN_MFA"
        case .email:
            return "EMAIL_OTP"
        }
    }

    /// The text that `"\(set)"` gave for a `Set<Amplify.MFAType>` before the fork, for example
    /// `[Amplify.MFAType.totp, Amplify.MFAType.sms]`. Error messages that interpolate a set of MFA types
    /// use it, so their text still names the public type. The element order is the set's own iteration
    /// order, which was never stable.
    static func legacyDescription(of types: Set<EngineMFAType>) -> String {
        "[" + types.map { "Amplify.MFAType.\($0.caseName)" }.joined(separator: ", ") + "]"
    }

    private var caseName: String {
        switch self {
        case .sms: return "sms"
        case .totp: return "totp"
        case .email: return "email"
        }
    }
}
