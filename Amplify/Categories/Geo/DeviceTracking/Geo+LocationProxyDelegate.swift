//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation

// A proxy delegate class to receive location updates
// for custom use cases
public class LocationProxyDelegate {
    public var didUpdatePositions: (([Position]) -> Void)?
    
    public init() { }
    
    public init(didUpdatePositions: @escaping ([Position]) -> Void) {
        self.didUpdatePositions = didUpdatePositions
    }
}

public struct Position {
    // timestamp of when position was received
    public let timeStamp: Date
    
    // coordinates of the position
    public let location: Geo.Location
    
    // tracker resource associated with the position
    public let tracker: String
    
    // device ID associated with the position
    public let deviceID: String
    
    public init(timeStamp: Date, location: Geo.Location, tracker: String, deviceID: String) {
        self.timeStamp = timeStamp
        self.location = location
        self.tracker = tracker
        self.deviceID = deviceID
    }
}
