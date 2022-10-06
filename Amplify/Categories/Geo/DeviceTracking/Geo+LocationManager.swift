//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation

public extension Geo {
    
    class LocationManager: CLLocationManager {
        
        /// Creates a new `Geo.LocationManager` based on the configurations in the `options` argument.
        /// - Parameters:
        ///   - options: A `Geo.LocationManager.TrackingSessionOptions` object that configures
        ///     the `Geo.LocationManager`.
        ///     Default argument is `defaultOptions`.
        public init(options: TrackingSessionOptions = .defaultOptions) {
            super.init()
            desiredAccuracy = options.desiredAccuracy.clLocationAccuracy
            if options.requestAlwaysAuthorization {
                requestAlwaysAuthorization()
            }
            allowsBackgroundLocationUpdates = options.allowsBackgroundLocationUpdates
            pausesLocationUpdatesAutomatically = options.pausesLocationUpdatesAutomatically
            activityType = options.activityType
            showsBackgroundLocationIndicator = options.showsBackgroundLocationIndicator
        }
    }

}


