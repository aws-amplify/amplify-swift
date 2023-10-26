//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    enum DeliveryMediumType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case email
        case sms
        case sdkUnknown(String)

        static var allCases: [DeliveryMediumType] {
            return [
                .email,
                .sms,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .email: return "EMAIL"
            case .sms: return "SMS"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = DeliveryMediumType(rawValue: rawValue) ?? DeliveryMediumType.sdkUnknown(rawValue)
        }
    }
}
