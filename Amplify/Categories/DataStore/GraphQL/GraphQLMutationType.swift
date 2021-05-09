//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Defines the type of a GraphQL mutation.
public enum GraphQLMutationType: String, Codable {

    /// <#Description#>
    case create

    /// <#Description#>
    case update

    /// <#Description#>
    case delete
}

extension GraphQLMutationType: CaseIterable { }
