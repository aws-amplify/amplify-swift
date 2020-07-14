//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public enum AuthStrategy {
    case owner
    case groups
    case `private`
    case `public`
}

/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public enum ModelOperation {
    case create
    case update
    case delete
    case read
}

/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public typealias AuthRules = [AuthRule]

/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public struct AuthRule {
    public let allow: AuthStrategy
    public let ownerField: String?
    public let identityClaim: String?
    public let groupClaim: String?
    public let groups: [String]
    public let groupsField: String?
    public let operations: [ModelOperation]

    public init(allow: AuthStrategy,
                ownerField: String? = nil,
                identityClaim: String? = nil,
                groupClaim: String? = nil,
                groups: [String] = [],
                groupsField: String? = nil,
                operations: [ModelOperation] = []) {
        self.allow = allow
        self.ownerField = ownerField
        self.identityClaim = identityClaim
        self.groupClaim = groupClaim
        self.groups = groups
        self.groupsField = groupsField
        self.operations = operations
    }
}
