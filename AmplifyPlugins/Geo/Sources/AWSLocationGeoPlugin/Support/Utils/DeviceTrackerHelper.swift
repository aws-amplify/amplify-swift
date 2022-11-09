//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class DeviceTrackingHelper {
    
    static func batchingThresholdReached(old: LocationUpdate,
                                         new: LocationUpdate,
                                         batchingOption: Geo.LocationManager.BatchingOption) -> Bool {
        switch batchingOption.batchingOptionType {
        case .none:
            return true
        case .distanceTravelledInMetres(let threshold):
            guard let oldLocation = old.location, let newLocation = new.location else {
                return false
            }
            return Int(newLocation.distance(from: oldLocation)) >= threshold
        case .secondsElapsed(let threshold):
            guard let oldTimeStamp = old.timeStamp, let newTimeStamp = new.timeStamp else {
                return false
            }
            return Int(newTimeStamp.timeIntervalSince(oldTimeStamp)) >= threshold
        }
    }
    
}
