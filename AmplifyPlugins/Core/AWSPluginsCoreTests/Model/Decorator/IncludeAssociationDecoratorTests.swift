//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore


class IncludeAssociationDecoratorTests: XCTestCase {

    // MARK: Setup

    override func setUp() {
        [
            // Post and Comment
            Post.self,
            Comment.self,
            // Book and Author
            Book.self,
            Author.self,
            BookAuthor.self
        ].forEach(ModelRegistry.register(modelType:))
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    // MARK: Utilities

    private func createSelectionSet<M: Model>(
        for modelType: M.Type,
        includes includedAssociations: IncludedAssociations<M> = { _ in [] }
    ) -> String {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .query,
                                                               primaryKeysOnly: true)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        guard let modelPath = modelType.rootPath as? ModelPath<M> else {
            XCTFail("Model path for \(modelType.modelName) not found. Make sure it was defined for the model")
            return ""
        }
        let included = includedAssociations(modelPath)
        documentBuilder.add(decorator: IncludeAssociationDecorator(included))
        guard let selectionSet = documentBuilder.build().selectionSet else {
            XCTFail("Selection set for \(modelType.modelName) is empty")
            return ""
        }
        return selectionSet.stringValue(indentSize: 0)
    }

    // MARK: Tests

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Comment`
    ///   - the belongTo `post` association is present in the schema
    ///   but not included in the selection set
    /// - Then:
    ///   - check if the generated selection set includes only the
    ///   `post` primary keys (i.e. the foreign key needed to associate both models)
    func testModelWithBelongsToWithoutIncludes() {
        let expectedSelectionSet =
            """
            id
            content
            createdAt
            post {
              id
              __typename
            }
            __typename
            """
        let selectionSet = createSelectionSet(for: Comment.self)
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Comment`
    ///   - the belongTo `post` association is present in the schema
    ///   and explicitly included in the query
    /// - Then:
    ///   - check if the generated selection set includes the entire `post` selection set
    func testModelWithIncludedBelongsTo() {
        let expectedSelectionSet =
            """
            id
            content
            createdAt
            post {
              id
              __typename
              content
              createdAt
              draft
              rating
              status
              title
              updatedAt
            }
            __typename
            """
        let selectionSet = createSelectionSet(for: Comment.self, includes: { comment in [comment.post] })
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Post`
    ///   - the hasMany `comments` association is present in the schema
    ///   but not included in the selection set
    /// - Then:
    ///   - check if the generated selection does not contain the `comments` field
    func testModelWithHasManyWithoutIncludes() {
        let expectedSelectionSet =
            """
            id
            content
            createdAt
            draft
            rating
            status
            title
            updatedAt
            __typename
            """
        let selectionSet = createSelectionSet(for: Post.self)
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Post`
    ///   - the hasMany `comments` association is present in the schema
    ///   and explicitly included in the query
    /// - Then:
    ///   - check if the generated selection set contains the `comments` field
    ///   - check if the generated selection set contains the `comments.post` keys
    func testModelWithIncludedHasMany() {
        let expectedSelectionSet =
            """
            id
            content
            createdAt
            draft
            rating
            status
            title
            updatedAt
            __typename
            comments {
              items {
                id
                content
                createdAt
                post {
                  id
                  __typename
                }
                __typename
              }
              nextToken
            }
            """
        let selectionSet = createSelectionSet(for: Post.self, includes: { post in [post.comments] })
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Book`
    ///   - the hasMany `authors` association is present in the schema
    /// - Then:
    ///   - check if the generated selection set doesn't include the `authors`
    func testBookModelWithNotIncludedManyToMany() {
        let expectedSelectionSet =
            """
            id
            title
            __typename
            """
        let selectionSet = createSelectionSet(for: Book.self)
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Book`
    ///   - the hasMany `authors` association is present in the schema
    ///   - the `book.authors.author` is included
    /// - Then:
    ///   - check if the generated selection set includes the `authors` selection set
    ///   - check if the generated selection set includes the `authors.author` selection set
    ///   - check if the generated selection set includes the `authors.book` keys only
    func testBookModelAndIncludeAuthorAssociationTwoLevelsDeep() {
        let expectedSelectionSet =
            """
            id
            title
            __typename
            authors {
              items {
                id
                author {
                  id
                  name
                  __typename
                }
                book {
                  id
                  __typename
                }
                __typename
              }
              nextToken
            }
            """
        let selectionSet = createSelectionSet(for: Book.self, includes: { book in
            [book.authors.author]
        })
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Author`
    ///   - the hasMany `books` association is present in the schema
    /// - Then:
    ///   - check if the generated selection set doesn't include the `books` selection set
    func testAuthorModelWithNotIncludedManyToMany() {
        let expectedSelectionSet =
            """
            id
            name
            __typename
            """
        let selectionSet = createSelectionSet(for: Author.self)
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Author`
    ///   - the hasMany `books` association is present in the schema
    ///   - the `author.books.book` is included
    /// - Then:
    ///   - check if the generated selection set includes the `books` selection set
    ///   - check if the generated selection set includes the `books.book` selection set
    ///   - check if the generated selection set includes the `books.author` keys only
    func testAuthorModelAndIncludeBookAssociationTwoLevelsDeep() {
        let expectedSelectionSet =
            """
            id
            name
            __typename
            books {
              items {
                id
                author {
                  id
                  __typename
                }
                book {
                  id
                  title
                  __typename
                }
                __typename
              }
              nextToken
            }
            """
        let selectionSet = createSelectionSet(for: Author.self, includes: { author in
            [author.books.book]
        })
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

    /// - Given: a `Model` schema
    /// - When:
    ///   - the model schema comes from the type `Author`
    ///   - the hasMany `books` association is present in the schema
    ///   - the `book.authors.author` is included
    ///   - the `book.authors.book` is included
    /// - Then:
    ///   - check if the generated selection set includes the `books` selection set
    ///   - check if the generated selection set includes the `books.author` selection set
    ///   - check if the generated selection set includes the `books.book` selection set
    func testAuthorModelAndIncludeBothAssociationsTwoLevelsDeep() {
        let expectedSelectionSet =
            """
            id
            name
            __typename
            books {
              items {
                id
                author {
                  id
                  __typename
                  name
                }
                book {
                  id
                  title
                  __typename
                }
                __typename
              }
              nextToken
            }
            """
        let selectionSet = createSelectionSet(for: Author.self, includes: { author in
            [author.books.book, author.books.author]
        })
        XCTAssertEqual(selectionSet, expectedSelectionSet)
    }

}
