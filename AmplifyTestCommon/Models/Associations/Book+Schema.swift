//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Amplify
import Foundation

public extension Book {

    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
        case title
        case authors
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let book = Book.keys

        model.fields(
            .id(),
            .field(book.title, is: .required, ofType: .string),
            .hasMany(
                book.authors,
                ofType: BookAuthor.self,
                associatedWith: BookAuthor.keys.author
            )
        )
    }

    class Path: ModelPath<Book> {}

    static var rootPath: PropertyContainerPath? { Path() }

}

extension ModelPath where ModelType == Book {
    var id: FieldPath<String> { id() }
    var authors: ModelPath<BookAuthor> { BookAuthor.Path(name: "authors", isCollection: true, parent: self) }
}
