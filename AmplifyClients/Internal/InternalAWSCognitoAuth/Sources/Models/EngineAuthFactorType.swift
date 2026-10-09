//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// The engine's copy of `Amplify.AuthFactorType`, with the plugin's `AuthFactorTypeExtension.swift`
/// members (`init?(rawValue:)`, `rawValue`, `challengeResponse`) copied onto it.
///
/// It is persisted inside `EngineAuthFlowType.userAuth` as `rawValue`, which is the Cognito challenge
/// name (`"PASSWORD"`, ...), not Amplify's own `String` raw value (`"password"`). Case names, platform
/// gating and log messages match the public type exactly. The plugin converts case to case in
/// `AWSCognitoAuthPlugin/Support/EngineBridge/AuthFactorType+Engine.swift`.
package enum EngineAuthFactorType {

    /// An auth factor that uses password
    case password

    /// An auth factor that uses SRP protocol
    case passwordSRP

    /// An auth factor that uses SMS OTP
    case smsOTP

    /// An auth factor that uses Email OTP
    case emailOTP

#if os(iOS) || os(macOS) || os(visionOS)
    /// An auth factor that uses WebAuthn
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    case webAuthn
#endif
}

extension EngineAuthFactorType: Sendable { }

package extension EngineAuthFactorType {

    /// The scope of the parser's lines: the public type's `DefaultLogger` category, written as a literal so
    /// the fork's name never shows.
    static let logScope = EngineLogScope.category("AuthFactorType")

    /// Parses a Cognito factor name, logging an unsupported one through `logger`, the caller's: the
    /// plugin's resolves the scope to `Amplify.Logging.logger(forCategory: "AuthFactorType")`, as before,
    /// and a standalone client's to its own category.
    init?(rawValue: String, logger: any EngineScopedLogger) {
        self.init(rawValue: rawValue, log: logger.scoped(Self.logScope))
    }

    /// The parse of the `AuthFlowType` decode (`EngineAuthFlowType.init(from:)`) when the decoder carries no
    /// `CodingUserInfoKey.engineLogger`: the one engine site with no caller's logger. It logs through the
    /// process-global router (`EngineLog`), as it always has. That is the plugin's decode, public and stored,
    /// and the accepted leak documented on `EngineLog`. The client's decodes set the key.
    init?(decodingRawValue rawValue: String) {
        self.init(rawValue: rawValue, log: EngineLog.logger(Self.logScope))
    }

    private init?(rawValue: String, log: EngineLogger) {
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
                log.error("WEB_AUTHN is not supported in this OS version.")
                return nil
            }
        #else
            log.error("WEB_AUTHN is only available in iOS and macOS.")
            return nil
        #endif
        default:
            log.error("Tried to initialize an unsupported MFA type with value: \(rawValue)")
            return nil
        }
    }

    /// String value of Auth Factor Type
    var rawValue: String {
        return challengeResponse
    }

    /// String value to be used as an input parameter  for confirmSignIn API
    var challengeResponse: String {
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
