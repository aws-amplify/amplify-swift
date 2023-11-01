//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    enum ObjectLockLegalHoldStatus: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case off
        case on
        case sdkUnknown(String)

        static var allCases: [ObjectLockLegalHoldStatus] {
            return [
                .off,
                .on,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .off: return "OFF"
            case .on: return "ON"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ObjectLockLegalHoldStatus(rawValue: rawValue) ?? ObjectLockLegalHoldStatus.sdkUnknown(rawValue)
        }
    }
}
