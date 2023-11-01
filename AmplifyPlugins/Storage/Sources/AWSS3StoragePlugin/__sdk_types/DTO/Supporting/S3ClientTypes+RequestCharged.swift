//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    /// If present, indicates that the requester was successfully charged for the request.
    enum RequestCharged: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case requester
        case sdkUnknown(String)

        static var allCases: [RequestCharged] {
            return [
                .requester,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .requester: return "requester"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = RequestCharged(rawValue: rawValue) ?? RequestCharged.sdkUnknown(rawValue)
        }
    }
}
