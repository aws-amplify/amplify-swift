//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    enum ChecksumAlgorithm: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case crc32
        case crc32c
        case sha1
        case sha256
        case sdkUnknown(String)

        static var allCases: [ChecksumAlgorithm] {
            return [
                .crc32,
                .crc32c,
                .sha1,
                .sha256,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .crc32: return "CRC32"
            case .crc32c: return "CRC32C"
            case .sha1: return "SHA1"
            case .sha256: return "SHA256"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ChecksumAlgorithm(rawValue: rawValue) ?? ChecksumAlgorithm.sdkUnknown(rawValue)
        }
    }
}
