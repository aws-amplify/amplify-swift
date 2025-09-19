//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Amplify
import Foundation

public extension BookAuthor {

    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
        case book
        case author
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let bookAuthor = BookAuthor.keys

        model.fields(
            .id(),
            .belongsTo(
                bookAuthor.book,
                ofType: Book.self,
                associatedWith: Book.keys.authors
            ),
            .belongsTo(
                bookAuthor.author,
                ofType: Author.self,
                associatedWith: Author.keys.books
            )
        )
    }

    class Path: ModelPath<BookAuthor> {}

    static var rootPath: PropertyContainerPath? { Path() }

}

extension ModelPath where ModelType == BookAuthor {
    var id: FieldPath<String> { id() }
    var book: ModelPath<Book> { Book.Path(name: "book", parent: self) }
    var author: ModelPath<Author> { Author.Path(name: "author", parent: self) }
}
