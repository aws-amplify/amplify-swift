//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    enum StorageClass: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case deepArchive
        case glacier
        case glacierIr
        case intelligentTiering
        case onezoneIa
        case outposts
        case reducedRedundancy
        case snow
        case standard
        case standardIa
        case sdkUnknown(String)

        static var allCases: [StorageClass] {
            return [
                .deepArchive,
                .glacier,
                .glacierIr,
                .intelligentTiering,
                .onezoneIa,
                .outposts,
                .reducedRedundancy,
                .snow,
                .standard,
                .standardIa,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .deepArchive: return "DEEP_ARCHIVE"
            case .glacier: return "GLACIER"
            case .glacierIr: return "GLACIER_IR"
            case .intelligentTiering: return "INTELLIGENT_TIERING"
            case .onezoneIa: return "ONEZONE_IA"
            case .outposts: return "OUTPOSTS"
            case .reducedRedundancy: return "REDUCED_REDUNDANCY"
            case .snow: return "SNOW"
            case .standard: return "STANDARD"
            case .standardIa: return "STANDARD_IA"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = StorageClass(rawValue: rawValue) ?? StorageClass.sdkUnknown(rawValue)
        }
    }
}
