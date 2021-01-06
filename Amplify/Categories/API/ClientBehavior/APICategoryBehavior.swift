//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the API category that clients will use
public typealias APICategoryBehavior =
    APICategoryRESTBehavior &
    APICategoryGraphQLBehavior &
    APICategoryInterceptorBehavior &
    APICategoryReachabilityBehavior &
    APICategoryAuthProviderFactoryBehavior
