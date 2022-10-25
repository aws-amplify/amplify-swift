//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation


public protocol LocationProxyDelegate {
    var didUpdateLocations : (CLLocationManager, [CLLocation]) -> Void { get set }
}

public enum UploadResponse {
    case success
    case failure(Failure)
    
    public struct Failure: Error {
        
        public let shouldRetry: Bool
        public let locations: [Geo.Location]
        
        public init(shouldRetry: Bool, locations: [Geo.Location]) {
            self.shouldRetry = shouldRetry
            self.locations = locations
        }
    }
}

