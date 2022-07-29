//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import AWSPluginsCore
import AmplifyTestCommon
@testable import Amplify

class ModelPrimaryKeyTests: XCTestCase {
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

    /// Given: a schema for model with a default primary key defined through the attribute `.primaryKey`
    /// When: a model primary key is built
    /// Then: the only primary key field is found
    func testFindPrimaryKeyDefaultIds() {
        let primaryKey = Post.schema.primaryKey
        XCTAssertEqual(primaryKey.isCompositeKey, false)
        XCTAssertEqual(primaryKey.fields.count, 1)
        XCTAssertEqual(primaryKey.fields[0].name, "id")
    }

    /// Given: a schema for model with an implicit default primary key defined through the attribute `.primaryKey`
    /// When: a model primary key is built
    /// Then: the only primary key field is found
    func testFindPrimaryKeyImplicitIds() {
        let primaryKey = ModelImplicitDefaultPk.schema.primaryKey
        XCTAssertEqual(primaryKey.isCompositeKey, false)
        XCTAssertEqual(primaryKey.fields.count, 1)
        XCTAssertEqual(primaryKey.fields[0].name, "id")
    }

    /// Given: a schema for model with an explicit  primary key field
    ///      defined through the attribute `.primaryKey`
    /// When: a model primary key is built
    /// Then: the only primary key field is found
    func testFindPrimaryKeyExplicitIds() {
        let primaryKey = ModelExplicitDefaultPk.schema.primaryKey
        XCTAssertEqual(primaryKey.isCompositeKey, false)
        XCTAssertEqual(primaryKey.fields.count, 1)
        XCTAssertEqual(primaryKey.fields[0].name, "id")
    }

    /// Given: a schema for model with a custom  primary key field
    ///      defined through the attribute `.primaryKey`
    /// When: a model primary key is built
    /// Then: the custom primary key field is found
    func testFindPrimaryKeyCustomField() {
        let primaryKey = ModelExplicitCustomPk.schema.primaryKey
        XCTAssertEqual(primaryKey.isCompositeKey, false)
        XCTAssertEqual(primaryKey.fields.count, 1)
        XCTAssertEqual(primaryKey.fields[0].name, "userId")
    }

    /// Given: a schema for model with a composite primary key field
    ///      defined through a model  index
    /// When: a model primary key is built
    /// Then: all the primary key fields are found
    func testFindCompositePrimaryKeyFields() {
        let primaryKey = ModelCompositePk.schema.primaryKey
        XCTAssertEqual(primaryKey.isCompositeKey, true)
        XCTAssertEqual(primaryKey.fields.count, 2)
        XCTAssertEqual(primaryKey.fields[0].name, "id")
        XCTAssertEqual(primaryKey.fields[1].name, "dob")
    }

    /// Given: a schema for model with a composite primary key field
    ///      defined through a model  index
    /// When: a model primary key is built
    /// Then: all the primary key fields are found
    func testFindCompositePrimaryKeyMultipleFields() {
        let primaryKey = CustomerWithMultipleFieldsinPK.schema.primaryKey
        let expectedFieldsNames = ["id", "dob", "date", "time", "phoneNumber", "priority", "height"]
        XCTAssertEqual(primaryKey.isCompositeKey, true)
        XCTAssertEqual(primaryKey.fields.count, 7)
        XCTAssertEqual(primaryKey.fields.map { $0.name }, expectedFieldsNames)
    }

    /// Given: a schema for model with a composite primary key field
    ///      defined through the `primaryKey` model pseudo field
    /// When: a model primary key is built
    /// Then: all the primary key fields are found
    func testFindCompositePrimaryKeyPseudoField() {
        let primaryKey = ModelCustomPkDefined.schema.primaryKey
        let expectedFieldsNames = ["id", "dob"]
        XCTAssertEqual(primaryKey.isCompositeKey, true)
        XCTAssertEqual(primaryKey.fields.count, 2)
        XCTAssertEqual(primaryKey.fields.map { $0.name }, expectedFieldsNames)
    }

    /// Given: a schema for model with a legacy composite primary key field
    /// When: a model primary key is built
    /// Then: all the primary key fields are found
    func testFindCompositePrimaryKeyLegacyModel() {
        let primaryKey = CustomerOrder.schema.primaryKey
        let expectedFieldsNames = ["orderId", "id"]
        XCTAssertEqual(primaryKey.isCompositeKey, true)
        XCTAssertEqual(primaryKey.fields.count, 2)
        XCTAssertEqual(primaryKey.fields.map { $0.name }, expectedFieldsNames)
    }

    /// Given: a schema for model with an untyped model
    /// When: a model primary key is built
    /// Then: the default id is found
    func testFindPrimaryKeyAnyModel() throws {
        let model = CustomerOrder(id: "someid", orderId: "orderid", email: "abc@abc.com")
        let untypedModel = try model.eraseToAnyModel()
        XCTAssertEqual(untypedModel.identifier, model.identifier)
    }
}
