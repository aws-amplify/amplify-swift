//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import AppSyncRealTimeClient

/// Protocol for the subscription factory
protocol SubscriptionConnectionFactory {

    /// Get connection based on the connection type
    func getOrCreateConnection(for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
                               authService: AWSAuthServiceBehavior,
                               apiAuthProviderFactory: APIAuthProviderFactory) throws -> SubscriptionConnection
}
