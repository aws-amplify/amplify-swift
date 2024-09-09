//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// swiftlint:disable all

public struct RecordCover: Model {
    public let id: String
    public var artist: String
    public let createdAt: Temporal.DateTime?
    public let updatedAt: Temporal.DateTime?

    public init(artist: String) {
        self.init(
            artist: artist,
            createdAt: nil,
            updatedAt: nil
        )
    }

    init(
        id: String = UUID().uuidString,
        artist: String,
        createdAt: Temporal.DateTime? = nil,
        updatedAt: Temporal.DateTime? = nil
    ) {
        self.id = id
        self.artist = artist
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
