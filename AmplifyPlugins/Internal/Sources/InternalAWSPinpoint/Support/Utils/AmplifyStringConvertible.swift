//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyStringConvertible: CustomStringConvertible, Encodable {}

extension AmplifyStringConvertible {
    private static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    public var description: String {
        if let data = try? Self.jsonEncoder.encode(self),
           let result = String(data: data, encoding: .utf8) {
            return result
        }

        return String(describing: self)
    }
}
