//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public struct Book: Model {

    public let id: String

    // hasMany(associatedWith: "book")
    public var authors: List<BookAuthor>

    public init(id: String = UUID().uuidString,
                authors: List<BookAuthor> = []) {
        self.id = id
        self.authors = authors
    }
}
