//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

// swiftlint:disable type_body_length
class ModelSortTests: XCTestCase {

    func testSortModelString() throws {
        var posts = [createPost(id: "1"),
                     createPost(id: "3"),
                     createPost(id: "2")]
        posts.sortModels(by: QuerySortBy.ascending(Post.keys.id).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].id, "1")
        XCTAssertEqual(posts[1].id, "2")
        XCTAssertEqual(posts[2].id, "3")
        posts.sortModels(by: QuerySortBy.descending(Post.keys.id).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].id, "3")
        XCTAssertEqual(posts[1].id, "2")
        XCTAssertEqual(posts[2].id, "1")
    }

    func testSortModelOptionalString() {
        var models = [QPredGen(name: "name", myString: "1"),
                      QPredGen(name: "name", myString: nil),
                      QPredGen(name: "name", myString: "2")]
        models.sortModels(by: QuerySortBy.ascending(QPredGen.keys.myString).sortDescriptor,
                          modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myString, nil)
        XCTAssertEqual(models[1].myString, "1")
        XCTAssertEqual(models[2].myString, "2")
        models.sortModels(by: QuerySortBy.descending(QPredGen.keys.myString).sortDescriptor,
                          modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myString, "2")
        XCTAssertEqual(models[1].myString, "1")
        XCTAssertEqual(models[2].myString, nil)
    }

    func testSortModelInt() {
        var models = [MutationSyncMetadata(
                        modelId: UUID().uuidString, modelName: "", deleted: false, lastChangedAt: 1, version: 1),
                      MutationSyncMetadata(
                        modelId: UUID().uuidString, modelName: "", deleted: false, lastChangedAt: 1, version: 2),
                      MutationSyncMetadata(
                        modelId: UUID().uuidString, modelName: "", deleted: false, lastChangedAt: 1, version: 3)]
        models.sortModels(by: QuerySortBy.ascending(MutationSyncMetadata.keys.version).sortDescriptor,
                          modelSchema: MutationSyncMetadata.schema)
        XCTAssertEqual(models[0].version, 1)
        XCTAssertEqual(models[1].version, 2)
        XCTAssertEqual(models[2].version, 3)
        models.sortModels(by: QuerySortBy.descending(MutationSyncMetadata.keys.version).sortDescriptor,
                          modelSchema: MutationSyncMetadata.schema)
        XCTAssertEqual(models[0].version, 3)
        XCTAssertEqual(models[1].version, 2)
        XCTAssertEqual(models[2].version, 1)
    }

    func testSortModelOptionalInt() {
        var models = [QPredGen(name: "name", myInt: 1),
                      QPredGen(name: "name", myInt: nil),
                      QPredGen(name: "name", myInt: 2)]
        models.sortModels(by: QuerySortBy.ascending(QPredGen.keys.myInt).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myInt, nil)
        XCTAssertEqual(models[1].myInt, 1)
        XCTAssertEqual(models[2].myInt, 2)
        models.sortModels(by: QuerySortBy.descending(QPredGen.keys.myInt).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myInt, 2)
        XCTAssertEqual(models[1].myInt, 1)
        XCTAssertEqual(models[2].myInt, nil)
    }

    func testSortModelDouble() {
        var posts = [createPost(rating: 2.0), createPost(rating: 1.0), createPost(rating: 3.0)]
        posts.sortModels(by: QuerySortBy.ascending(Post.keys.rating).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].rating, 1.0)
        XCTAssertEqual(posts[1].rating, 2.0)
        XCTAssertEqual(posts[2].rating, 3.0)
        posts.sortModels(by: QuerySortBy.descending(Post.keys.rating).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].rating, 3.0)
        XCTAssertEqual(posts[1].rating, 2.0)
        XCTAssertEqual(posts[2].rating, 1.0)
    }

    func testSortModelOptionalDouble() {
        var models = [QPredGen(name: "name", myDouble: 1.1),
                      QPredGen(name: "name", myDouble: nil),
                      QPredGen(name: "name", myDouble: 2.2)]
        models.sortModels(by: QuerySortBy.ascending(QPredGen.keys.myDouble).sortDescriptor,
                          modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myDouble, nil)
        XCTAssertEqual(models[1].myDouble, 1.1)
        XCTAssertEqual(models[2].myDouble, 2.2)
        models.sortModels(by: QuerySortBy.descending(QPredGen.keys.myDouble).sortDescriptor,
                          modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myDouble, 2.2)
        XCTAssertEqual(models[1].myDouble, 1.1)
        XCTAssertEqual(models[2].myDouble, nil)
    }

    func testSortModelDate() {
        let date1 = Temporal.Date.now()
        let date2 = Temporal.Date.now().add(value: 1, to: .day)
        let date3 = Temporal.Date.now().add(value: 2, to: .day)
        var models = [createModel(date: date1),
                      createModel(date: date2),
                      createModel(date: date3)]
        models.sortModels(by: QuerySortBy.ascending(ExampleWithEveryType.keys.dateField).sortDescriptor,
                          modelSchema: ExampleWithEveryType.schema)
        XCTAssertEqual(models[0].dateField, date1)
        XCTAssertEqual(models[1].dateField, date2)
        XCTAssertEqual(models[2].dateField, date3)
        models.sortModels(by: QuerySortBy.descending(ExampleWithEveryType.keys.dateField).sortDescriptor,
                          modelSchema: ExampleWithEveryType.schema)
        XCTAssertEqual(models[0].dateField, date3)
        XCTAssertEqual(models[1].dateField, date2)
        XCTAssertEqual(models[2].dateField, date1)
    }

    func testSortModelOptionalDate() {
        let date1 = Temporal.Date.now().add(value: 1, to: .day)
        let date2 = Temporal.Date.now().add(value: 2, to: .day)
        var models = [QPredGen(name: "name", myDate: date1),
                      QPredGen(name: "name", myDate: nil),
                      QPredGen(name: "name", myDate: date2)]
        models.sortModels(by: QuerySortBy.ascending(QPredGen.keys.myDate).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myDate, nil)
        XCTAssertEqual(models[1].myDate, date1)
        XCTAssertEqual(models[2].myDate, date2)
        models.sortModels(by: QuerySortBy.descending(QPredGen.keys.myDate).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myDate, date2)
        XCTAssertEqual(models[1].myDate, date1)
        XCTAssertEqual(models[2].myDate, nil)
    }

    func testSortModelDateTime() {
        let dateTime1 = Temporal.DateTime.now()
        let dateTime2 = Temporal.DateTime.now().add(value: 1, to: .day)
        let dateTime3 = Temporal.DateTime.now().add(value: 2, to: .day)
        var posts = [createPost(createdAt: dateTime1),
                     createPost(createdAt: dateTime2),
                     createPost(createdAt: dateTime3)]
        posts.sortModels(by: QuerySortBy.ascending(Post.keys.createdAt).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].createdAt, dateTime1)
        XCTAssertEqual(posts[1].createdAt, dateTime2)
        XCTAssertEqual(posts[2].createdAt, dateTime3)
        posts.sortModels(by: QuerySortBy.descending(Post.keys.createdAt).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].createdAt, dateTime3)
        XCTAssertEqual(posts[1].createdAt, dateTime2)
        XCTAssertEqual(posts[2].createdAt, dateTime1)
    }

    func testSortModelOptionalDateTime() {
        let datetime1 = Temporal.DateTime.now().add(value: 1, to: .day)
        let datetime2 = Temporal.DateTime.now().add(value: 2, to: .day)
        var models = [QPredGen(name: "name", myDateTime: datetime1),
                      QPredGen(name: "name", myDateTime: nil),
                      QPredGen(name: "name", myDateTime: datetime2)]
        models.sortModels(by: QuerySortBy.ascending(QPredGen.keys.myDateTime).sortDescriptor,
                          modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myDateTime, nil)
        XCTAssertEqual(models[1].myDateTime, datetime1)
        XCTAssertEqual(models[2].myDateTime, datetime2)
        models.sortModels(by: QuerySortBy.descending(QPredGen.keys.myDateTime).sortDescriptor,
                          modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myDateTime, datetime2)
        XCTAssertEqual(models[1].myDateTime, datetime1)
        XCTAssertEqual(models[2].myDateTime, nil)
    }

    func testSortModelTime() {
        let time1 = Temporal.Time.now()
        let time2 = Temporal.Time.now().add(value: 2, to: .day)
        let time3 = Temporal.Time.now().add(value: 3, to: .day)
        var models = [QPredGen(name: "name", myTime: time2),
                      QPredGen(name: "name", myTime: time1),
                      QPredGen(name: "name", myTime: time3)]

        models.sortModels(by: QuerySortBy.ascending(QPredGen.keys.myTime).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myTime, time1)
        XCTAssertEqual(models[1].myTime, time2)
        XCTAssertEqual(models[2].myTime, time3)

        models.sortModels(by: QuerySortBy.descending(QPredGen.keys.myTime).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myTime, time3)
        XCTAssertEqual(models[1].myTime, time2)
        XCTAssertEqual(models[2].myTime, time1)
    }

    func testSortModelOptionalTime() {
        let time1 = Temporal.Time.now().add(value: 1, to: .day)
        let time2 = Temporal.Time.now().add(value: 2, to: .day)
        var models = [QPredGen(name: "name", myTime: time1),
                      QPredGen(name: "name", myTime: nil),
                      QPredGen(name: "name", myTime: time2)]

        models.sortModels(by: QuerySortBy.ascending(QPredGen.keys.myTime).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myTime, nil)
        XCTAssertEqual(models[1].myTime, time1)
        XCTAssertEqual(models[2].myTime, time2)

        models.sortModels(by: QuerySortBy.descending(QPredGen.keys.myTime).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myTime, time2)
        XCTAssertEqual(models[1].myTime, time1)
        XCTAssertEqual(models[2].myTime, nil)
    }

    func testSortModelBool() {
        var models = [createModel(bool: false),
                      createModel(bool: true),
                      createModel(bool: false)]
        models.sortModels(by: QuerySortBy.ascending(ExampleWithEveryType.keys.boolField).sortDescriptor,
                          modelSchema: ExampleWithEveryType.schema)
        XCTAssertEqual(models[0].boolField, false)
        XCTAssertEqual(models[1].boolField, false)
        XCTAssertEqual(models[2].boolField, true)
        models.sortModels(by: QuerySortBy.descending(ExampleWithEveryType.keys.boolField).sortDescriptor,
                          modelSchema: ExampleWithEveryType.schema)
        XCTAssertEqual(models[0].boolField, true)
        XCTAssertEqual(models[1].boolField, false)
        XCTAssertEqual(models[2].boolField, false)
    }

    func testSortModelOptionalBool() {
        var models = [QPredGen(name: "name", myBool: true),
                      QPredGen(name: "name", myBool: nil),
                      QPredGen(name: "name", myBool: false)]
        models.sortModels(by: QuerySortBy.ascending(QPredGen.keys.myBool).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myBool, nil)
        XCTAssertEqual(models[1].myBool, false)
        XCTAssertEqual(models[2].myBool, true)
        models.sortModels(by: QuerySortBy.descending(QPredGen.keys.myBool).sortDescriptor, modelSchema: QPredGen.schema)
        XCTAssertEqual(models[0].myBool, true)
        XCTAssertEqual(models[1].myBool, false)
        XCTAssertEqual(models[2].myBool, nil)
    }

    func testSortModelEnum() {
        var models = [createModel(enum: .bar),
                      createModel(enum: .foo),
                      createModel(enum: .bar)]
        models.sortModels(by: QuerySortBy.ascending(ExampleWithEveryType.keys.enumField).sortDescriptor,
                          modelSchema: ExampleWithEveryType.schema)
        XCTAssertEqual(models[0].enumField, .bar)
        XCTAssertEqual(models[1].enumField, .bar)
        XCTAssertEqual(models[2].enumField, .foo)
        models.sortModels(by: QuerySortBy.descending(ExampleWithEveryType.keys.enumField).sortDescriptor,
                          modelSchema: ExampleWithEveryType.schema)
        XCTAssertEqual(models[0].enumField, .foo)
        XCTAssertEqual(models[1].enumField, .bar)
        XCTAssertEqual(models[2].enumField, .bar)
    }

    func testSortModelOptionalEnum() {
        var posts = [createPost(status: .draft),
                     createPost(status: .private),
                     createPost(status: .published),
                     createPost(status: nil)]
        posts.sortModels(by: QuerySortBy.ascending(Post.keys.status).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].status, nil)
        XCTAssertEqual(posts[1].status, .draft)
        XCTAssertEqual(posts[2].status, .private)
        XCTAssertEqual(posts[3].status, .published)
        posts.sortModels(by: QuerySortBy.descending(Post.keys.status).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].status, .published)
        XCTAssertEqual(posts[1].status, .private)
        XCTAssertEqual(posts[2].status, .draft)
        XCTAssertEqual(posts[3].status, nil)
    }

    func testSortByTwoFields() {
        let dateTime1 = Temporal.DateTime.now()
        let dateTime2 = Temporal.DateTime.now().add(value: 1, to: .day)
        let dateTime3 = Temporal.DateTime.now().add(value: 2, to: .day)
        var posts = [createPost(rating: 1.0, createdAt: dateTime2),
                     createPost(rating: 1.0, createdAt: dateTime1),
                     createPost(rating: 2.0, createdAt: dateTime3)]

        posts.sortModels(by: QuerySortBy.ascending(Post.keys.rating).sortDescriptor, modelSchema: Post.schema)
        // overall order does not change since ratings are already in asecnding order
        XCTAssertEqual(posts[0].rating, 1.0)
        XCTAssertEqual(posts[0].createdAt, dateTime1)
        XCTAssertEqual(posts[1].rating, 1.0)
        XCTAssertEqual(posts[1].createdAt, dateTime2)
        XCTAssertEqual(posts[2].rating, 2.0)
        XCTAssertEqual(posts[2].createdAt, dateTime3)

        posts.sortModels(by: QuerySortBy.ascending(Post.keys.createdAt).sortDescriptor, modelSchema: Post.schema)
        XCTAssertEqual(posts[0].rating, 1.0)
        XCTAssertEqual(posts[0].createdAt, dateTime1)
        XCTAssertEqual(posts[1].rating, 1.0)
        XCTAssertEqual(posts[1].createdAt, dateTime2)
        XCTAssertEqual(posts[2].rating, 2.0)
        XCTAssertEqual(posts[2].createdAt, dateTime3)
    }

    // MARK: - Helpers

    func createPost(id: String = UUID().uuidString,
                    draft: Bool = false,
                    rating: Double = 1.0,
                    createdAt: Temporal.DateTime = .now(),
                    status: PostStatus? = .draft) -> Post {
        Post(id: id,
             title: "A",
             content: "content",
             createdAt: createdAt,
             updatedAt: .now(),
             draft: draft,
             rating: rating,
             status: status,
             comments: nil)
    }

    func createModel(date: Temporal.Date = .now(),
                     bool: Bool = false,
                     enum: ExampleEnum = .bar) -> ExampleWithEveryType {
        ExampleWithEveryType(id: UUID().uuidString,
                             stringField: "string",
                             intField: 1,
                             doubleField: 1.0,
                             boolField: bool,
                             dateField: date,
                             enumField: `enum`,
                             nonModelField: .init(someString: "some string",
                                                  someEnum: .bar),
                             arrayOfStringsField: [])
    }
}
