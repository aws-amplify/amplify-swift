//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation

public class LocationProxyDelegate {
    public var didUpdateLocations: (([Position]) -> Void)?
    
    public init() { }
    
    public init(didUpdateLocations: @escaping ([Position]) -> Void) {
        self.didUpdateLocations = didUpdateLocations
    }
}

public struct Position {
    public let timeStamp: Date
    public let latitude: Double
    public let longitude: Double
    public let tracker: String
    public let deviceID: String
    
    public init(timeStamp: Date, latitude: Double, longitude: Double, tracker: String, deviceID: String) {
        self.timeStamp = timeStamp
        self.latitude = latitude
        self.longitude = longitude
        self.tracker = tracker
        self.deviceID = deviceID
    }
}
