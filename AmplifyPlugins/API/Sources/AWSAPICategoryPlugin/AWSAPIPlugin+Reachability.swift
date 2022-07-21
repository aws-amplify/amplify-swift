//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Combine

extension AWSAPIPlugin {
    public func reachabilityPublisher() throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        return try reachabilityPublisher(for: nil)
    }

    public func reachabilityPublisher(for apiName: String?) throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        let endpoint = try pluginConfig.endpoints.getConfig(for: apiName)
        guard let hostName = endpoint.baseURL.host else {
            let error = APIError.invalidConfiguration("Invalid endpoint configuration",
                """
                baseURL does not contain a valid hostname
                """
            )
            throw error
        }

        return reachabilityMapLock.execute {
            if let networkReachability = reachabilityMap[hostName] {
                return networkReachability.publisher
            }
            do {
                let networkReachability = try NetworkReachabilityNotifier(host: hostName,
                                                                          allowsCellularAccess: true,
                                                                          reachabilityFactory: AmplifyReachability.self)
                reachabilityMap[hostName] = networkReachability
                return networkReachability.publisher
            } catch {
                Amplify.API.log.error("Unable to initialize NetworkReachabilityNotifier: \(error)")
                return nil
            }
        }
    }
}
