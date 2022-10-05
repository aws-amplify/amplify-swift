//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Geo {
    public struct DeleteLocationOptions {
        public let tracker: String?
        
        public init(tracker: String? = nil) {
            self.tracker = tracker
        }
    }
}
