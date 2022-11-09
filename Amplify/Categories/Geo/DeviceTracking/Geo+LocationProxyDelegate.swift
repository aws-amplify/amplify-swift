//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation

public class LocationProxyDelegate {
    public var didUpdatePositions: (([Position]) -> Void)?
    
    public init() { }
    
    public init(didUpdatePositions: @escaping ([Position]) -> Void) {
        self.didUpdatePositions = didUpdatePositions
    }
}

public struct Position {
    public let timeStamp: Date
    public let location: Geo.Location
    public let tracker: String
    public let deviceID: String
    
    public init(timeStamp: Date, location: Geo.Location, tracker: String, deviceID: String) {
        self.timeStamp = timeStamp
        self.location = location
        self.tracker = tracker
        self.deviceID = deviceID
    }
}
