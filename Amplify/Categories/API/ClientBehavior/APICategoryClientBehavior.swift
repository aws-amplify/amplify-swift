//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//swiftlint:disable colon
/// Behavior of the API category that clients will use
public protocol APICategoryClientBehavior:
    APICategoryRESTBehavior &
    APICategoryGraphQLBehavior &
    APICategoryInterceptorBehavior { }
//swiftlint:enable colon
