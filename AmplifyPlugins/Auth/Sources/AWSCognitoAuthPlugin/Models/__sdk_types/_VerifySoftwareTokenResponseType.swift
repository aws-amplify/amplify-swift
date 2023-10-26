//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    enum VerifySoftwareTokenResponseType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case error
        case success
        case sdkUnknown(String)

        static var allCases: [VerifySoftwareTokenResponseType] {
            return [
                .error,
                .success,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .error: return "ERROR"
            case .success: return "SUCCESS"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = VerifySoftwareTokenResponseType(rawValue: rawValue) ?? VerifySoftwareTokenResponseType.sdkUnknown(rawValue)
        }
    }
}
