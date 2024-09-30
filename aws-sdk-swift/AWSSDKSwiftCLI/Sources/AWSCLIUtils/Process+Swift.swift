//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Process {
    struct Swift {
        /// Returns a process for executing swift commands.
        private func swiftProcess(_ args: [String]) -> Process {
            Process(["swift"] + args)
        }
        
        /// Returns a process for executing `swift test`
        public func test() -> Process {
            swiftProcess(["test"])
        }
    }
    
    static var swift: Swift { Swift() }
}
