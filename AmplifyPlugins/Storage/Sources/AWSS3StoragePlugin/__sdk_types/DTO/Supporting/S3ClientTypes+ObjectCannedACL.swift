//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation


extension S3ClientTypes {
    enum ObjectCannedACL: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case authenticatedRead
        case awsExecRead
        case bucketOwnerFullControl
        case bucketOwnerRead
        case `private`
        case publicRead
        case publicReadWrite
        case sdkUnknown(String)

        static var allCases: [ObjectCannedACL] {
            return [
                .authenticatedRead,
                .awsExecRead,
                .bucketOwnerFullControl,
                .bucketOwnerRead,
                .private,
                .publicRead,
                .publicReadWrite,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .authenticatedRead: return "authenticated-read"
            case .awsExecRead: return "aws-exec-read"
            case .bucketOwnerFullControl: return "bucket-owner-full-control"
            case .bucketOwnerRead: return "bucket-owner-read"
            case .private: return "private"
            case .publicRead: return "public-read"
            case .publicReadWrite: return "public-read-write"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ObjectCannedACL(rawValue: rawValue) ?? ObjectCannedACL.sdkUnknown(rawValue)
        }
    }
}
