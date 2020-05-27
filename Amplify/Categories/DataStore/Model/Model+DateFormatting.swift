//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct ModelDateFormatting {

    public static let decodingStrategy: JSONDecoder.DateDecodingStrategy = {
        let strategy = JSONDecoder.DateDecodingStrategy.custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let dateTime = try Temporal.DateTime(iso8601String: dateString)
            return dateTime.foundationDate
        }

        return strategy
    }()

    public static let encodingStrategy: JSONEncoder.DateEncodingStrategy = {
        let strategy = JSONEncoder.DateEncodingStrategy.custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Temporal.DateTime(date).iso8601String)
        }
        return strategy
    }()

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
