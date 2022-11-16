//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct PositionInternal: Identifiable, Codable {
    
    let id: String
    let timeStamp: Date
    let latitude: Double
    let longitude: Double
    let tracker: String
    
    init(
        id: String = UUID().uuidString,
        timeStamp: Date,
        latitude: Double,
        longitude: Double,
        tracker: String
    ) {
        self.id = id
        self.timeStamp = timeStamp
        self.latitude = latitude
        self.longitude = longitude
        self.tracker = tracker
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case timeStamp
        case latitude
        case longitude
        case tracker
    }

    public static let keys = CodingKeys.self
    
}

extension PositionInternal: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id)
    }
}
