//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    enum DeviceRememberedStatusType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case notRemembered
        case remembered
        case sdkUnknown(String)

        static var allCases: [DeviceRememberedStatusType] {
            return [
                .notRemembered,
                .remembered,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .notRemembered: return "not_remembered"
            case .remembered: return "remembered"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = DeviceRememberedStatusType(rawValue: rawValue) ?? DeviceRememberedStatusType.sdkUnknown(rawValue)
        }
    }
}
