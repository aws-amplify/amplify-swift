//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    enum ServerSideEncryption: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case aes256
        case awsKms
        case awsKmsDsse
        case sdkUnknown(String)

        static var allCases: [ServerSideEncryption] {
            return [
                .aes256,
                .awsKms,
                .awsKmsDsse,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .aes256: return "AES256"
            case .awsKms: return "aws:kms"
            case .awsKmsDsse: return "aws:kms:dsse"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ServerSideEncryption(rawValue: rawValue) ?? ServerSideEncryption.sdkUnknown(rawValue)
        }
    }
}
