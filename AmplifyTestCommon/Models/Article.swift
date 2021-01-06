//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Article: Model {
    public let id: String
    public var content: String
    public var createdAt: Temporal.DateTime
    public var owner: String?
    public var authorNotes: String?

    public init(id: String = UUID().uuidString,
                content: String,
                createdAt: Temporal.DateTime,
                owner: String?,
                authorNotes: String?) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.owner = owner
        self.authorNotes = authorNotes
    }
}
