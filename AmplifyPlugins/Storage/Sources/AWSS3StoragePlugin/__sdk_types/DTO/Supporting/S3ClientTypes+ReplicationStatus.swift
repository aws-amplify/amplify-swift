//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    public enum ReplicationStatus: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case complete
        case failed
        case pending
        case replica
        case sdkUnknown(Swift.String)

        public static var allCases: [ReplicationStatus] {
            return [
                .complete,
                .failed,
                .pending,
                .replica,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .complete: return "COMPLETE"
            case .failed: return "FAILED"
            case .pending: return "PENDING"
            case .replica: return "REPLICA"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ReplicationStatus(rawValue: rawValue) ?? ReplicationStatus.sdkUnknown(rawValue)
        }
    }
}
