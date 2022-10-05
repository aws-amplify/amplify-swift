//
//  File.swift
//  
//
//  Created by Pham, Tuan on 9/26/22.
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
