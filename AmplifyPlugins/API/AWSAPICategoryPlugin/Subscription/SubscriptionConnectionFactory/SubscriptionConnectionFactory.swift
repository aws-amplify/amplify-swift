//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore

protocol SubscriptionConnectionFactory {

    func getOrCreateConnection(for endpointConfiguration: AWSAPICategoryPluginConfiguration.EndpointConfig,
                               authService: AWSAuthServiceBehavior) throws -> SubscriptionConnection
}
