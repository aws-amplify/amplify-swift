//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public struct Author: Model {

    public let id: String
    public let name: String

    // hasMany(associatedWith: "author")
    public var books: List<BookAuthor>

    public init(id: String = UUID().uuidString,
                name: String,
                books: List<BookAuthor> = []) {
        self.id = id
        self.name = name
        self.books = books
    }
}
