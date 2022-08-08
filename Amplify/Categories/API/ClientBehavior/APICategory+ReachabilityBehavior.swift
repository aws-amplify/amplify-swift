//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Foundation
import Combine

extension APICategory: APICategoryReachabilityBehavior {

    /// Default implementation of `reachabilityPublisher` to delegate to plugin's method
    public func reachabilityPublisher(for apiName: String?) throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        return try plugin.reachabilityPublisher(for: apiName)
    }

    /// Default implementation of `reachabilityPublisher` to delegate to plugin's method
    public func reachabilityPublisher() throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        return try plugin.reachabilityPublisher(for: nil)
    }
}
#endif
