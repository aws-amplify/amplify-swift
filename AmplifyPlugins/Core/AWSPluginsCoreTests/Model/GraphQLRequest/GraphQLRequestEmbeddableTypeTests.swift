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

class GraphQLRequestEmbeddableTypeTests: XCTestCase {

    override func setUp() async throws {
        ModelRegistry.register(modelType: Todo.self)
    }

    override func tearDown() async throws {
        ModelRegistry.reset()
    }

    func testCreateTodoGraphQLRequest() {
        let color1 = Color(name: "color1", red: 1, green: 2, blue: 3)
        let color2 = Color(name: "color2", red: 12, green: 13, blue: 14)
        let category1 = Category(name: "green", color: color1)
        let category2 = Category(name: "red", color: color2)
        let section = Section(name: "section", number: 1.1)
        let todo = Todo(name: "my first todo",
                        description: "todo description",
                        categories: [category1, category2],
                        section: section)
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
        let request = GraphQLRequest<Todo>.create(todo)
        XCTAssertEqual(documentStringValue, request.document)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input["id"] as? String, todo.id)
    }
}

class GraphQLRequestJSONNonModelTests: XCTestCase {

    override func setUp() async throws {
        let sectionName =  ModelField(name: "name",
                                    type: .string,
                                    isRequired: true)
        let sectionNumber =  ModelField(name: "number",
                                 type: .double,
                                 isRequired: true)
        let sectionSchema = ModelSchema(name: "Section",
                                fields: [sectionName.name: sectionName,
                                         sectionNumber.name: sectionNumber])

        let colorName =  ModelField(name: "name",
                                    type: .string,
                                    isRequired: true)
        let colorR =  ModelField(name: "red",
                                 type: .int,
                                 isRequired: true)
        let colorG =  ModelField(name: "green",
                                 type: .int,
                                 isRequired: true)
        let colorB =  ModelField(name: "blue",
                                 type: .int,
                                 isRequired: true)
        let colorSchema = ModelSchema(name: "Color", listPluralName: "Colors", syncPluralName: "Colors",
                                fields: [colorName.name: colorName,
                                         colorR.name: colorR,
                                         colorG.name: colorG,
                                         colorB.name: colorB])

        let categoryName = ModelField(name: "name",
                                      type: .string,
                                      isRequired: true)
        let categoryColor = ModelField(name: "color",
                                       type: .embeddedCollection(of: DynamicEmbedded.self, schema: colorSchema),
                                       isRequired: true)
        let categorySchema = ModelSchema(name: "Category", listPluralName: "Categories", syncPluralName: "Categories",
                                         fields: [categoryName.name: categoryName,
                                                  categoryColor.name: categoryColor])

        let todoId = ModelFieldDefinition.id("id").modelField
        let todoName = ModelField(name: "name",
                                  type: .string,
                                  isRequired: true)
        let todoDescription = ModelField(name: "description",
                                         type: .string)
        let todoCategories = ModelField(name: "categories",
                                        type: .embeddedCollection(of: DynamicEmbedded.self, schema: categorySchema))
        let todoSection = ModelField(name: "section",
                                     type: .embedded(type: DynamicEmbedded.self, schema: sectionSchema))
        let todoStickies = ModelField(name: "stickies",
                                     type: .embedded(type: String.self))
        let todoSchema = ModelSchema(name: "Todo",
                                     listPluralName: "Todos",
                                     syncPluralName: "Todos",
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

    override func tearDown() async throws {
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
    }
}
