//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Defines the type of a GraphQL subscription.
public enum GraphQLSubscriptionType: String {

    /// <#Description#>
    case onCreate

    /// <#Description#>
    case onDelete

    /// <#Description#>
    case onUpdate
}

extension GraphQLSubscriptionType: CaseIterable { }
