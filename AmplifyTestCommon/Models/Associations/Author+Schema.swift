//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension Author {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case name
        case books
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let author = Author.keys

        model.fields(
            .id(),
            .field(author.name, is: .required, ofType: .string),
            .hasMany(author.books,
                     ofType: BookAuthor.self,
                     associatedWith: BookAuthor.keys.book)
        )
    }

    public class Path : ModelPath<Author> {}

    public static var rootPath: PropertyContainerPath? { Path() }

}

extension ModelPath where ModelType == Author {
    var id: FieldPath<String> { id() }
    var name: FieldPath<String> { string("name") }
    var books: ModelPath<BookAuthor> { BookAuthor.Path(name: "books", isCollection: true, parent: self) }
}
