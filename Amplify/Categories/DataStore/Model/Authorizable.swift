//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: enums

public enum AuthStrategy {
    case owner
    case groups
    case `private`
    case `public`
}

public enum AuthProvider {
    case apiKey
    case iam
    case oidc
    case userPools
}

public enum ModelOperation {
    case create
    case update
    case delete
    case read
}

public struct AuthRule {
    public let allow: AuthStrategy
    public let field: CodingKey?
    public let provider: AuthProvider?
    public let ownerField: CodingKey?
    public let identityClaim: String?
    public let groupClaim: String?
    public let groups: [String]
    public let groupsField: CodingKey?
    public let operations: [ModelOperation]
}

public typealias AuthRules = [AuthRule]

// MARK: protocol

public protocol Authorizable {
    static var authRules: AuthRules { get }
}
