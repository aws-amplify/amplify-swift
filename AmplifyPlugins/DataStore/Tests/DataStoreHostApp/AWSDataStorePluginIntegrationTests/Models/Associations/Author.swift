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

    // hasMany(associatedWith: "author")
    public var books: List<BookAuthor>

    public init(id: String = UUID().uuidString,
                books: List<BookAuthor> = []) {
        self.id = id
        self.books = books
    }
}
