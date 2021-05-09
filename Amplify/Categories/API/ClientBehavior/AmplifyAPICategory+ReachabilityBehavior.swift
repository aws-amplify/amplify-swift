//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
extension AmplifyAPICategory: APICategoryReachabilityBehavior {
    /// <#Description#>
    /// - Parameter apiName: <#apiName description#>
    /// - Throws: <#description#>
    /// - Returns: <#description#>
    @available(iOS 13.0, *)
    public func reachabilityPublisher(for apiName: String?) throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        return try plugin.reachabilityPublisher(for: apiName)
    }

    /// <#Description#>
    /// - Throws: <#description#>
    /// - Returns: <#description#>
    @available(iOS 13.0, *)
    public func reachabilityPublisher() throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        return try plugin.reachabilityPublisher(for: nil)
    }
}
