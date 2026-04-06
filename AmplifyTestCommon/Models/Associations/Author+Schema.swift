//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Amplify
import Foundation

public extension Author {

    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
        case name
        case books
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let author = Author.keys

        model.fields(
            .id(),
            .field(author.name, is: .required, ofType: .string),
            .hasMany(
                author.books,
                ofType: BookAuthor.self,
                associatedWith: BookAuthor.keys.book
            )
        )
    }

    class Path: ModelPath<Author> {}

    static var rootPath: PropertyContainerPath? { Path() }

}

extension ModelPath where ModelType == Author {
    var id: FieldPath<String> { id() }
    var name: FieldPath<String> { string("name") }
    var books: ModelPath<BookAuthor> { BookAuthor.Path(name: "books", isCollection: true, parent: self) }
}
