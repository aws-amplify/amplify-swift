//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public struct BookAuthor: Model {

    public let id: String

    // belongsTo
    public var author: Author

    // belongsTo
    public let book: Book

    public init(id: String = UUID().uuidString,
                book: Book,
                author: Author) {
        self.id = id
        self.book = book
        self.author = author
    }
}
