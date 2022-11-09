//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation

public extension Geo {
    
    struct LocationAccuracy {
        public let clLocationAccuracy: CLLocationAccuracy

        public init(clLocationAccuracy: CLLocationAccuracy) {
            self.clLocationAccuracy = clLocationAccuracy
        }
            
        public static let coarse = Self(clLocationAccuracy: kCLLocationAccuracyHundredMeters)
        public static let fine = Self(clLocationAccuracy: kCLLocationAccuracyBest)
    }
    
    struct BatchingOption {
        /// Note: Although this has `public` access, it is intended for internal use
        /// and should not be used directly by host applications.
        ///
        /// Send batch of location updates to Amazon Location Service (or `LocationProxyDelegate` if set)
        /// after at least this distance has been travelled. The computation of
        /// distance travelled is defined as straight-line distance between the last saved
        /// location and the most recent location in the batch
        public let _metersTravelled : Int?
      
        /// Note: Although this has `public` access, it is intended for internal use
        /// and should not be used directly by host applications.
        ///
        /// Number of seconds elapsed since sending location update(s) to Amazon
        /// Location Service (or `LocationProxyDelegate` if set) before location updates are sent again.
        public let _secondsElapsed : Int?
        
        init(metersTravelled: Int? = nil, secondsElapsed: Int? = nil) {
            self._metersTravelled = metersTravelled
            self._secondsElapsed = secondsElapsed
        }
        
        public static let none = BatchingOption()
           
        public static func distanceTravelled(meters threshold: Int) -> BatchingOption {
            .init(metersTravelled: threshold)
        }
           
        public static func timeElapsed(seconds threshold: Int) -> BatchingOption {
            .init(secondsElapsed: threshold)
        }
    }
    
    
    struct TrackingSessionOptions {
        
        /// Name of tracker resource. Set to the default tracker if no tracker is passed in.
        public var tracker: String?
        
        /// The desired accuracy level of location updates.
        /// This should be treated as a request
        /// - no guarantees are made that the `desiredAccuracy` level will be acheived.
        public let desiredAccuracy: LocationAccuracy
        
        /// If `true`, this will call `requestAlwaysAuthorization()`,
        /// which triggers the OS dialog requesting always permission to always receive device location updates.
        public let requestAlwaysAuthorization: Bool
        
        /// Whether background location updates should be allowed.
        /// If `true`, location updates will be received from the OS while the app is backgrounded.
        /// You must include the UIBackgroundModes key (with the location value) in your app’s Info.plist file
        /// if you want to set this value to `true`. Not doing so can result in a fatal error that terminates the app.
        ///
        /// If `false`, location updates will only be received while the app is in the foreground.
        public let allowsBackgroundLocationUpdates: Bool
        
        /// Allows the OS to decide to pause location updates based on battery saving criteria.
        public let pausesLocationUpdatesAutomatically: Bool
        
        /// Applicable if `pausesLocationUpdatesAutomatically` is `true`.
        /// Based on the `activityType` the OS will decide appropriate times to pause location updates to improve battery life.
        public let activityType: CLActivityType
        
        /// Only applicable when `requestAlwaysAuthorization` is `true`.
        /// This determines whether a user sees the background location indicator.
        /// Default value is `false`.  This option is not supported for MacOS.
        public let showsBackgroundLocationIndicator: Bool
        
        /// By default this will persist location updates if the service
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
        public let batchingOption: BatchingOption
        
        /// Receives location updates. Default implementation is to send location
        /// updates to Amazon Location service.
        public let locationProxyDelegate: LocationProxyDelegate
        
        /// Setting a proxy delegate will notify the delegate of location updates instead of
        /// sending location updates to Amazon Location service
        public func withProxyDelegate(_ proxyDelegate: LocationProxyDelegate) -> Self {
            self.locationProxyDelegate.didUpdatePositions = proxyDelegate.didUpdatePositions
            return self
        }
        
        public init(
            tracker: String? = nil,
            desiredAccuracy: LocationAccuracy = .fine,
            requestAlwaysAuthorization: Bool = true,
            allowsBackgroundLocationUpdates: Bool = false,
            pausesLocationUpdatesAutomatically: Bool = true,
            activityType: CLActivityType = .automotiveNavigation,
            showsBackgroundLocationIndicator: Bool = false,
            disregardLocationUpdatesWhenOffline: Bool = false,
            wakeAppForSignificantLocationChanges: Bool = false,
            distanceFilter: CLLocationDistance = 0,
            trackUntil: Date = .distantFuture,
            batchingOption: BatchingOption = .none,
            locationProxyDelegate: LocationProxyDelegate = LocationProxyDelegate()
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
            self.batchingOption = batchingOption
            self.locationProxyDelegate = locationProxyDelegate
        }
        
        public init(options: TrackingSessionOptions) {
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
                      trackUntil: options.trackUntil,
                      batchingOption: options.batchingOption,
                      locationProxyDelegate: options.locationProxyDelegate)
        }
    }
}

public extension Geo.BatchingOption {
    
    struct LocationUpdate {
        var timeStamp: Date?
        var position: CLLocation?
        
        public init(timeStamp: Date? = nil,
                    position: CLLocation? = nil) {
            self.timeStamp = timeStamp
            self.position = position
        }
    }
}
