//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct ModelDateFormatting {
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601WithoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public static let decodingStrategy: JSONDecoder.DateDecodingStrategy = {
        let strategy = JSONDecoder.DateDecodingStrategy.custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = iso8601WithFractionalSeconds.date(from: dateString) {
                return date
            }

            if let date = iso8601WithoutFractionalSeconds.date(from: dateString) {
                return date
            }

            return try container.decode(Date.self)
        }

        return strategy
    }()

    public static let encodingStrategy: JSONEncoder.DateEncodingStrategy = {
        let strategy = JSONEncoder.DateEncodingStrategy.custom { date, encoder in
            let dateString = iso8601WithFractionalSeconds.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        }
        return strategy
    }()

}

public extension Date {

    /// Retrieve the ISO 8601 formatted String, like "2019-11-25T00:35:01.746Z", from the Date instance
    var iso8601String: String {
        return ModelDateFormatting.iso8601WithFractionalSeconds.string(from: self)
    }
}

public extension String {

    /// Retrieve the ISO 8601 Date for valid String values like "2019-11-25T00:35:01.746Z". Supports values with and
    /// without fractional seconds.
    var iso8601Date: Date? {
        if let date = ModelDateFormatting.iso8601WithFractionalSeconds.date(from: self) {
            return date
        }
        return ModelDateFormatting.iso8601WithoutFractionalSeconds.date(from: self)
    }
}

public extension JSONDecoder {
    convenience init(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy) {
        self.init()
        self.dateDecodingStrategy = dateDecodingStrategy
    }
}

public extension JSONEncoder {
    convenience init(dateEncodingStrategy: JSONEncoder.DateEncodingStrategy) {
        self.init()
        self.dateEncodingStrategy = dateEncodingStrategy
    }
}
