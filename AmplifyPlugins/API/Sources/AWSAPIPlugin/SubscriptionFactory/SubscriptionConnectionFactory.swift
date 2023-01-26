//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import AWSPluginsCore
import AppSyncRealTimeClient

/// Protocol for the subscription factory
protocol SubscriptionConnectionFactory {

    /// Get connection based on the connection type
    func getOrCreateConnection(for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
                               urlRequest: URLRequest,
                               authService: AWSAuthServiceBehavior,
                               authType: AWSAuthorizationType?,
                               apiAuthProviderFactory: APIAuthProviderFactory) throws -> SubscriptionConnection
}
