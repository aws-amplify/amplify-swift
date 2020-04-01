//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Combine
import Reachability

extension AWSAPIPlugin {
    @available(iOS 13.0, *)
    public func reachabilityPublisher() throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        return try reachabilityPublisher(for: nil)
    }

    @available(iOS 13.0, *)
    public func reachabilityPublisher(for apiName: String?) throws -> AnyPublisher<ReachabilityUpdate, Never>? {
        let hostName = try determineHostName(apiName: apiName)
        if let networkReachability = reachabilityMap[hostName] {
            return networkReachability.publisher
        }
        do {
            let networkReachability = try NetworkReachabilityNotifier(host: hostName,
                                                                      allowsCellularAccess: true,
                                                                      reachabilityFactory: Reachability.self)
            reachabilityMap[hostName] = networkReachability
            return networkReachability.publisher
        } catch {
            Amplify.API.log.error("Unable to initialize NetworkReachabilityNotifier: \(error)")
            return nil
        }
    }

    private func determineHostName(apiName: String?) throws -> String {
        if let apiName = apiName {
            guard let baseUrl = pluginConfig.endpoints[apiName]?.baseURL,
                let host = baseUrl.host else {
                    let error = APIError.invalidConfiguration("Invalid endpoint configuration for \(apiName)",
                                                              """
                                                              baseURL does not contain a valid hostname
                                                              for apiName: \(apiName)
                                                              """
                    )
                    throw error
            }
            return host
        }

        if pluginConfig.endpoints.count > 1 {
            let error = APIError.invalidConfiguration("Unable to determine which endpoint configuration",
                                                      """
                                                      Pass in the apiName to disambiguate between which endpoint
                                                      you are requesting reachability for
                                                      """
            )
            throw error
        }

        guard let configEntry = pluginConfig.endpoints.first else {
            let error = APIError.invalidConfiguration("No API configurations found",
                                                      """
                                                      Review how the API category is being instantiated and
                                                      configured.
                                                      """
            )
            throw error
        }

        guard let host = configEntry.value.baseURL.host else {
            let error = APIError.invalidConfiguration("Invalid endpoint configuration",
                """
                baseURL does not contain a valid hostname
                """
            )
            throw error
        }
        return host
    }

}
