//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    enum ArchiveStatus: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case archiveAccess
        case deepArchiveAccess
        case sdkUnknown(String)

        static var allCases: [ArchiveStatus] {
            return [
                .archiveAccess,
                .deepArchiveAccess,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .archiveAccess: return "ARCHIVE_ACCESS"
            case .deepArchiveAccess: return "DEEP_ARCHIVE_ACCESS"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ArchiveStatus(rawValue: rawValue) ?? ArchiveStatus.sdkUnknown(rawValue)
        }
    }
}
