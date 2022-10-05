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
       public let tracker: String?
       
       public init(tracker: String? = nil, metadata: [String: String]? = nil) {
           self.tracker = tracker
           self.metadata = metadata
       }
    }
}
