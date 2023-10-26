//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {

    enum AuthFlowType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case adminNoSrpAuth
        case adminUserPasswordAuth
        case customAuth
        case refreshToken
        case refreshTokenAuth
        case userPasswordAuth
        case userSrpAuth
        case sdkUnknown(String)

        static var allCases: [AuthFlowType] {
            return [
                .adminNoSrpAuth,
                .adminUserPasswordAuth,
                .customAuth,
                .refreshToken,
                .refreshTokenAuth,
                .userPasswordAuth,
                .userSrpAuth,
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
            case .adminUserPasswordAuth: return "ADMIN_USER_PASSWORD_AUTH"
            case .customAuth: return "CUSTOM_AUTH"
            case .refreshToken: return "REFRESH_TOKEN"
            case .refreshTokenAuth: return "REFRESH_TOKEN_AUTH"
            case .userPasswordAuth: return "USER_PASSWORD_AUTH"
            case .userSrpAuth: return "USER_SRP_AUTH"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = AuthFlowType(rawValue: rawValue) ?? AuthFlowType.sdkUnknown(rawValue)
        }
    }
}
