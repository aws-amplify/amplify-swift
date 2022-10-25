//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation

public extension Geo.LocationManager {
    
    struct LocationAccuracy {
        public let clLocationAccuracy: CLLocationAccuracy

        public init(clLocationAccuracy: CLLocationAccuracy) {
            self.clLocationAccuracy = clLocationAccuracy
        }
            
        public static let coarse = Self(clLocationAccuracy: kCLLocationAccuracyHundredMeters)
        public static let fine = Self(clLocationAccuracy: kCLLocationAccuracyBest)
    }
    
    struct BatchingOptions {
        public let threshold: Int
        public let thresholdReached: (Int) -> Bool
        
        public static let `none` = BatchingOptions(threshold: 0, thresholdReached: { _ in true })
        
        public static func secondsElapsed(_ threshold: Int) -> BatchingOptions {
            BatchingOptions(threshold: threshold) { $0 >= threshold }
        }
        
        public static func distanceTravelledInMeters(_ threshold: Int) -> BatchingOptions {
            BatchingOptions(threshold: threshold) { $0 >= threshold }
        }
    }
    
    class TrackingSessionOptions {
        
        /// Name of tracker resource. Set to the default tracker if no tracker is passed in.
        public var tracker: String?
        
        /// The desired accuracy level of location updates.
        /// This should be treated as a request
        /// - no guarantees are made that the `desiredAccuracy` level will be acheived.
        public let desiredAccuracy: LocationAccuracy
        
        /// If `true`, the Geo.LocationManager will call `requestAlwaysAuthorization()`,
        /// which triggers the OS dialog requesting always permission to always receive device location updates.
        public let requestAlwaysAuthorization: Bool
        
        /// Whether background location updates should be allowed.
        /// If `true`, location updates will be received from the OS while the app is backgrounded.
        /// If `false`, location updates will only be received while the app is in the foreground.
        public let allowsBackgroundLocationUpdates: Bool
        
        /// Allows the OS to decide to pause location updates based on battery saving criteria.
        public let pausesLocationUpdatesAutomatically: Bool
        
        /// Applicable if `pausesLocationUpdatesAutomatically` is `true`.
        /// Based on the `activityType` the OS will decide appropriate times to pause location updates to improve battery life.
        public let activityType: CLActivityType
        
        /// Only applicable when `requestAlwaysAuthorization` is `true`.
        /// This determines whether a user sees the background location indicator.
        /// Default value is `false`.
        public let showsBackgroundLocationIndicator: Bool
        
        /// By default the Geo.LocationManager will persist location updates if the service
        /// cannot be reached due to loss of network connectivity, and send the updates once
        /// an update is possible.
        /// Setting this value to `true` will disable this behavior.
        public let disregardLocationUpdatesWhenOffline: Bool
        
        /// Setting this to true will request that the app be woken up by significant location
        /// updates after an app has been force closed.
        /// In order to take advantage of this, you'll need to call `Amplify.Geo.startTracking()` in your apps launch lifecycle method. (e.g. `didFinishedLoading`)
        /// Default value is `false`.
        public let wakeAppForSignificantLocationChanges: Bool
        
        /// The minimum distance in meters at which the operating system will update the app with
        /// a new location. This can be beneficial when battery consumption is important.
        public let distanceFilter: CLLocationDistance
        
        /// The date and time after which to stop tracking. By default, tracking will
        /// continue until stopTracking(...) is called.
        public let trackUntil: Date
        
        /// Custom defined behavior that allows for location updates to be batched up to a certain threshold
        /// before sending the collected updates as a batch.
        public let batchingOptions: BatchingOptions
        
        public var proxyDelegate : LocationProxyDelegate?
        
        public func withProxyDelegate(_ proxyDelegate: LocationProxyDelegate) -> Self {
            self.proxyDelegate = proxyDelegate
            return self
        }
        
        public init(
            tracker: String? = nil,
            desiredAccuracy: LocationAccuracy = .fine,
            requestAlwaysAuthorization: Bool = true,
            allowsBackgroundLocationUpdates: Bool = true,
            pausesLocationUpdatesAutomatically: Bool = true,
            activityType: CLActivityType = .automotiveNavigation,
            showsBackgroundLocationIndicator: Bool = false,
            disregardLocationUpdatesWhenOffline: Bool = false,
            wakeAppForSignificantLocationChanges: Bool = false,
            distanceFilter: CLLocationDistance = 0,
            batchingOptions: BatchingOptions = .none,
            trackUntil: Date = .distantFuture
        ) {
            self.tracker = tracker
            self.desiredAccuracy = desiredAccuracy
            self.requestAlwaysAuthorization = requestAlwaysAuthorization
            self.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
            self.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
            self.activityType = activityType
            self.showsBackgroundLocationIndicator = showsBackgroundLocationIndicator
            self.disregardLocationUpdatesWhenOffline = disregardLocationUpdatesWhenOffline
            self.wakeAppForSignificantLocationChanges = wakeAppForSignificantLocationChanges
            self.distanceFilter = distanceFilter
            self.trackUntil = trackUntil
            self.batchingOptions = batchingOptions
        }
        
        public convenience init(options: TrackingSessionOptions) {
            self.init(tracker: options.tracker,
                      desiredAccuracy: options.desiredAccuracy,
                      requestAlwaysAuthorization: options.requestAlwaysAuthorization,
                      allowsBackgroundLocationUpdates: options.allowsBackgroundLocationUpdates,
                      pausesLocationUpdatesAutomatically: options.allowsBackgroundLocationUpdates,
                      activityType: options.activityType,
                      showsBackgroundLocationIndicator: options.showsBackgroundLocationIndicator,
                      disregardLocationUpdatesWhenOffline: options.disregardLocationUpdatesWhenOffline,
                      wakeAppForSignificantLocationChanges: options.wakeAppForSignificantLocationChanges,
                      distanceFilter: options.distanceFilter,
                      batchingOptions: options.batchingOptions,
                      trackUntil: options.trackUntil)
        }
    }
}
