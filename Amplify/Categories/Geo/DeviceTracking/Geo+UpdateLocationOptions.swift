//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Geo {
    public struct UpdateLocationOptions {
       public let metadata: [String: String]?
        
       // Name of tracker resource. Set to default tracker if no tracker is passed in.
       public let tracker: String?
       
       // Corresponds to Amazon Location Service's PositionProperties (a map that can
       // contain at most 3 key-value pairs). Default is an empty map.
       public init(tracker: String? = nil, metadata: [String: String]? = nil) {
           self.tracker = tracker
           self.metadata = metadata
       }
    }
}
