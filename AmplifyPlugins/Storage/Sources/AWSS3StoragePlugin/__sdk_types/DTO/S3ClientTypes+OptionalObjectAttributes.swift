//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    enum OptionalObjectAttributes: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case restoreStatus
        case sdkUnknown(String)

        static var allCases: [OptionalObjectAttributes] {
            return [
                .restoreStatus,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .restoreStatus: return "RestoreStatus"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = OptionalObjectAttributes(rawValue: rawValue) ?? OptionalObjectAttributes.sdkUnknown(rawValue)
        }
    }
}
