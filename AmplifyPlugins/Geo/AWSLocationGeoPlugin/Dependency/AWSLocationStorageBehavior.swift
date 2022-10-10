//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AWSLocationStorageBehavior {
    
    func save(position: Position) throws
    
    func save(positions: [Position]) throws
    
    func delete(position: Position) throws
    
    func delete(positions: [Position]) throws
    
    func queryAll() throws -> [Position]
    
    func deleteAll() throws
}

struct Position: Identifiable, Codable {
    
    let id: String
    let timeStamp: String
    let latitude: Double
    let longitude: Double
    let tracker: String
    let deviceID: String
    
    init(
        id: String = UUID().uuidString,
        timeStamp: String,
        latitude: Double,
        longitude: Double,
        tracker: String,
        deviceID: String
    ) {
        self.id = id
        self.timeStamp = timeStamp
        self.latitude = latitude
        self.longitude = longitude
        self.tracker = tracker
        self.deviceID = deviceID
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case timeStamp
        case latitude
        case longitude
        case tracker
        case deviceID
    }

    public static let keys = CodingKeys.self
    
}
