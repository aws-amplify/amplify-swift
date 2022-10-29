//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreLocation


public class LocationProxyDelegate {
    public var didUpdateLocations: (([Geo.Location]) -> Void)?
    
    public init() { }
    
    public init(didUpdateLocations: @escaping ([Geo.Location]) -> Void) {
        self.didUpdateLocations = didUpdateLocations
    }
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

