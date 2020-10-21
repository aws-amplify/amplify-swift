//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class GraphQLRequestEmbeddableTypeJSONTests: XCTestCase {

    override func setUp() {
        let sectionName =  ModelField(name: "name", type: .string, isRequired: true)
        let sectionNumber =  ModelField(name: "number", type: .double, isRequired: true)
        let sectionSchema = ModelSchema(name: "Section",
                                        fields: [sectionName.name: sectionName,
                                                 sectionNumber.name: sectionNumber])

        let colorName =  ModelField(name: "name", type: .string, isRequired: true)
        let colorR =  ModelField(name: "red", type: .int, isRequired: true)
        let colorG =  ModelField(name: "green", type: .int, isRequired: true)
        let colorB =  ModelField(name: "blue", type: .int, isRequired: true)
        let colorSchema = ModelSchema(name: "Color", pluralName: "Colors",
                                      fields: [colorName.name: colorName,
                                               colorR.name: colorR,
                                               colorG.name: colorG,
                                               colorB.name: colorB])

        let categoryName = ModelField(name: "name", type: .string, isRequired: true)
        let categoryColor = ModelField(name: "color",
                                       type: .embeddedCollection(of: DynamicEmbedded.self, schema: colorSchema),
                                       isRequired: true)
        let categorySchema = ModelSchema(name: "Category", pluralName: "Categories",
                                         fields: [categoryName.name: categoryName,
                                                  categoryColor.name: categoryColor])

        let todoId = ModelFieldDefinition.id("id").modelField
        let todoName = ModelField(name: "name", type: .string, isRequired: true)
        let todoDescription = ModelField(name: "description", type: .string)
        let todoCategories = ModelField(name: "categories",
                                        type: .embeddedCollection(of: DynamicEmbedded.self, schema: categorySchema))
        let todoSection = ModelField(name: "section",
                                     type: .embedded(type: DynamicEmbedded.self, schema: sectionSchema))
        let todoStickies = ModelField(name: "stickies", type: .embedded(type: String.self))
        let todoSchema = ModelSchema(name: "Todo",
                                     pluralName: "Todos",
                                     fields: [todoId.name: todoId,
                                              todoName.name: todoName,
                                              todoDescription.name: todoDescription,
                                              todoCategories.name: todoCategories,
                                              todoSection.name: todoSection,
                                              todoStickies.name: todoStickies])

        ModelRegistry.register(modelType: DynamicModel.self,
                               modelSchema: todoSchema) { (_, _) -> Model in
            return DynamicModel(id: "1", map: [:])
        }
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testCreateTodoGraphQLRequest() {
        let color1 = ["name": JSONValue.string("color1"),
                      "red": JSONValue.number(1),
                      "green": JSONValue.number(2),
                      "blue": JSONValue.number(3)]
        let color2 = ["name": JSONValue.string("color1"),
                      "red": JSONValue.number(12),
                      "green": JSONValue.number(13),
                      "blue": JSONValue.number(14)]

        let category1 = ["name": JSONValue.string("green"), "color": JSONValue.object(color1)]
        let category2 = ["name": JSONValue.string("red"), "color": JSONValue.object(color2)]

        let section = ["name": JSONValue.string("section"), "number": JSONValue.number(1.1)]

        let todo = ["name": JSONValue.string("my first todo"),
                    "description": JSONValue.string("todo description"),
                    "categories": JSONValue.array([JSONValue.object(category1), JSONValue.object(category2)]),
                    "section": JSONValue.object(section)]

        let todoModel = DynamicModel(map: todo)
        let documentStringValue = """
        mutation CreateTodo($input: CreateTodoInput!) {
          createTodo(input: $input) {
            id
            categories {
              color {
                blue
                green
                name
                red
                __typename
              }
              name
              __typename
            }
            description
            name
            section {
              name
              number
              __typename
            }
            stickies
            __typename
          }
        }
        """
        let schema = ModelRegistry.modelSchema(from: "Todo")!
        let request = GraphQLRequest<DynamicModel>.create(todoModel, modelSchema: schema)
        XCTAssertEqual(documentStringValue, request.document)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input["id"] as? String, todoModel.id)
    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is a `Post`
    ///   - the mutation is of type `.create`
    /// - Then:
    ///   - check if the `GraphQLRequest` is valid:
    ///     - the `document` has the right content
    ///     - the `responseType` is correct
    ///     - the `variables` is non-nil
    func testCreateMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.create(post)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testUpdateMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.update(post)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testDeleteMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.delete(post)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testQueryByIdGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.get(Post.self, byId: "id")

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post?.self)
        XCTAssert(request.variables != nil)
    }

    func testListQueryGraphQLRequest() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        documentBuilder.add(decorator: PaginationDecorator())
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.list(Post.self, where: predicate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == [Post].self)
        XCTAssertNotNil(request.variables)
    }

    func testPaginatedListQueryGraphQLRequest() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        documentBuilder.add(decorator: PaginationDecorator(limit: 10))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.paginatedList(Post.self, where: predicate, limit: 10)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == List<Post>.self)
        XCTAssertNotNil(request.variables)
    }

    func testOnCreateSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onCreate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)

    }

    func testOnUpdateSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onUpdate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
    }

    func testOnDeleteSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onDelete)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
    }
}
