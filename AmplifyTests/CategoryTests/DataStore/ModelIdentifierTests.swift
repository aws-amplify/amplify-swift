//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AmplifyTestCommon

class ModelIdentifierTests: XCTestCase {
    override func setUp() {

        // default primary keys models
        ModelRegistry.register(modelType: Post.self)

        // custom primary keys models
        ModelRegistry.register(modelType: ModelImplicitDefaultPk.self)
        ModelRegistry.register(modelType: ModelExplicitDefaultPk.self)
        ModelRegistry.register(modelType: ModelExplicitCustomPk.self)

        ModelRegistry.register(modelType: ModelCompositePk.self)

        // custom pk based on indexes
        ModelRegistry.register(modelType: CustomerWithMultipleFieldsinPK.self)

        // custom pk based on primaryKey field
        ModelRegistry.register(modelType: ModelCustomPkDefined.self)

        // legacy pk
        ModelRegistry.register(modelType: CustomerOrder.self)
    }

    // MARK: - ModelIdentifier string value

    func testModelIdentifierDefaultId() {
        let model = Post(title: "title", content: "", createdAt: Temporal.DateTime.now())
        XCTAssertEqual(model.identifier, model.id)
    }

    func testModelIdentifierImplicitDefault() {
        let model = ModelImplicitDefaultPk(name: "name")
        XCTAssertEqual(model.identifier, model.id)
    }

    func testModelIdentifierExplicitId() {
        let model = ModelExplicitDefaultPk(name: "name")
        XCTAssertEqual(model.identifier, model.id)
    }

    func testModelIdentifierCustomField() {
        let model = ModelExplicitCustomPk(userId: "userId")
        XCTAssertEqual(model.identifier, model.userId)
    }

    func testModelIdentifierCompositeKey() {
        let model = ModelCompositePk(id: "id", dob: Temporal.DateTime.now(), name: "name")
        XCTAssertEqual(model.identifier, "\"\(model.id)\"#\"\(model.dob.iso8601String)\"")
    }

    func testModelIdentifierLegacyModel() {
        let model = CustomerOrder(id: "123-456", orderId: "order-id", email: "hello@abc.com")
        XCTAssertEqual(model.identifier, "\"\(model.orderId)\"#\"\(model.id)\"")
    }

    // MARK: - ModelIdentifier predicate

    func testModelIdentifierDefaultIdPredicate() {
        let model = Post(title: "title", content: "", createdAt: Temporal.DateTime.now())

        let predicate = (model.identifier(schema: Post.schema).predicate as? QueryPredicateOperation)!

        XCTAssertEqual(predicate, Post.keys.id == model.id)
    }

    func testModelIdentifierImplicitDefaultPredicate() {
        let model = ModelImplicitDefaultPk(name: "name")

        let identifier = model.identifier(schema: ModelImplicitDefaultPk.schema)

        let predicate = (identifier.predicate as? QueryPredicateOperation)!

        XCTAssertEqual(predicate, ModelImplicitDefaultPk.keys.id == model.id)
    }

    func testModelIdentifierExplicitIdPredicate() {
        let model = ModelExplicitDefaultPk(name: "name")

        let identifier = model.identifier(schema: ModelExplicitDefaultPk.schema)

        let predicate = (identifier.predicate as? QueryPredicateOperation)!

        XCTAssertEqual(predicate, ModelExplicitDefaultPk.keys.id == model.id)
    }

    func testModelIdentifierCustomFieldPredicate() {
        let model = ModelExplicitCustomPk(userId: "userId")

        let identifier = model.identifier(schema: ModelExplicitCustomPk.schema)

        let predicate = (identifier.predicate as? QueryPredicateOperation)!

        XCTAssertEqual(predicate, ModelExplicitCustomPk.keys.userId == model.userId)

    }

    func testModelIdentifierCompositePredicate() {
        let model = ModelCompositePk(id: "id",
                                     dob: Temporal.DateTime.now(),
                                     name: "name")

        let identifier = model.identifier(schema: ModelCompositePk.schema)

        let predicate = (identifier.predicate as? QueryPredicateGroup)!

        let keys = ModelCompositePk.keys

        let expectedPredicate = keys.dob == model.dob && keys.id == model.id

        XCTAssertEqual(predicate.type, expectedPredicate.type)
        XCTAssertEqual(predicate.predicates.count, expectedPredicate.predicates.count)
        XCTAssertEqual(predicate, expectedPredicate)

    }
}
