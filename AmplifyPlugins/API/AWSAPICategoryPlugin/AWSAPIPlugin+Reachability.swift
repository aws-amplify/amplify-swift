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
    @available(iOS 13.0, *)
    public func reachabilityPublisher() throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        return try reachabilityPublisher(for: nil)
    }

    @available(iOS 13.0, *)
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
        var result: AnyPublisher<ReachabilityUpdate, Never>?
        reachabilityMap.with { map in // return `iReachability's dictionary as a new AtomicValue's value
            if let networkReachability = map[hostName] {
                result = networkReachability.publisher
            }
            do {
                let networkReachability = try NetworkReachabilityNotifier(host: hostName,
                                                                          allowsCellularAccess: true,
                                                                          reachabilityFactory: AmplifyReachability.self)
                map[hostName] = networkReachability // update the new A
                reachabilityMap = AtomicValue(initialValue: map) // data race here too
                result = networkReachability.publisher
            } catch {
                Amplify.API.log.error("Unable to initialize NetworkReachabilityNotifier: \(error)")
            }
        }

        return result
    }
}
