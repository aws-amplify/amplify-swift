//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {

    enum ChallengeNameType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case adminNoSrpAuth
        case customChallenge
        case devicePasswordVerifier
        case deviceSrpAuth
        case mfaSetup
        case newPasswordRequired
        case passwordVerifier
        case selectMfaType
        case smsMfa
        case softwareTokenMfa
        case sdkUnknown(String)

        static var allCases: [ChallengeNameType] {
            return [
                .adminNoSrpAuth,
                .customChallenge,
                .devicePasswordVerifier,
                .deviceSrpAuth,
                .mfaSetup,
                .newPasswordRequired,
                .passwordVerifier,
                .selectMfaType,
                .smsMfa,
                .softwareTokenMfa,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .adminNoSrpAuth: return "ADMIN_NO_SRP_AUTH"
            case .customChallenge: return "CUSTOM_CHALLENGE"
            case .devicePasswordVerifier: return "DEVICE_PASSWORD_VERIFIER"
            case .deviceSrpAuth: return "DEVICE_SRP_AUTH"
            case .mfaSetup: return "MFA_SETUP"
            case .newPasswordRequired: return "NEW_PASSWORD_REQUIRED"
            case .passwordVerifier: return "PASSWORD_VERIFIER"
            case .selectMfaType: return "SELECT_MFA_TYPE"
            case .smsMfa: return "SMS_MFA"
            case .softwareTokenMfa: return "SOFTWARE_TOKEN_MFA"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ChallengeNameType(rawValue: rawValue) ?? ChallengeNameType.sdkUnknown(rawValue)
        }
    }
}
