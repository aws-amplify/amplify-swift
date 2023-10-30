//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    enum ObjectLockMode: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case compliance
        case governance
        case sdkUnknown(String)

        static var allCases: [ObjectLockMode] {
            return [
                .compliance,
                .governance,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .compliance: return "COMPLIANCE"
            case .governance: return "GOVERNANCE"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ObjectLockMode(rawValue: rawValue) ?? ObjectLockMode.sdkUnknown(rawValue)
        }
    }
}
