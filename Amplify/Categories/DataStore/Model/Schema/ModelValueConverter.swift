//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol ModelValueConverter {

    associatedtype SourceType
    associatedtype TargetType

    func convertToTarget(from source: SourceType, fieldType: ModelFieldType) throws -> TargetType

    func convertToSource(from target: TargetType, fieldType: ModelFieldType) throws -> SourceType

}

extension ModelValueConverter {

    static var decoder: JSONDecoder {
        JSONDecoder(dateDecodingStrategy: ModelDateFormatting.decodingStrategy)
    }

    static var encoder: JSONEncoder {
        JSONEncoder(dateEncodingStrategy: ModelDateFormatting.encodingStrategy)
    }

    public static func toJSON(_ value: Encodable) throws -> String? {
        let data = try encoder.encode(value.eraseToAnyEncodable())
        return String(data: data, encoding: .utf8)
    }

    public static func fromJSON(_ value: String) throws -> [String: Any]? {
        guard let data = value.data(using: .utf8) else {
            return nil
        }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
