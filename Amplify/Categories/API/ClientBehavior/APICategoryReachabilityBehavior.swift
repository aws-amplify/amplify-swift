//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
public protocol APICategoryReachabilityBehavior {
    /// Attempts to create and start a reachability client for a host that corresponds to the apiName, and then
    /// returns the associated Publisher which vends ReachabiltyUpdates
    /// - Parameters:
    ///   - for: The corresponding apiName that maps to the plugin configuration
    /// - Returns: A publisher that receives reachability updates, or nil if the reachability subsystem is unavailable
    @available(iOS 13.0, *)
    func reachabilityPublisher(for apiName: String?) throws -> AnyPublisher<ReachabilityUpdate, Never>?

    @available(iOS 13.0, *)
    func reachabilityPublisher() throws -> AnyPublisher<ReachabilityUpdate, Never>?

}
