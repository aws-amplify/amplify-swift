//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable type_body_length
class SQLiteStorageEngineAdapterTests: BaseDataStoreTests {

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `query(Post)` to check if the model was correctly inserted
    func testInsertPost() {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        let post = Post(title: "title", content: "content", createdAt: .now())
        storageAdapter.save(post) { saveResult in
            switch saveResult {
            case .success:
                self.storageAdapter.query(Post.self) { queryResult in
                    switch queryResult {
                    case .success(let posts):
                        XCTAssert(posts.count == 1)
                        if let savedPost = posts.first {
                            XCTAssert(post.id == savedPost.id)
                            XCTAssert(post.title == savedPost.title)
                            XCTAssert(post.content == savedPost.content)
                            XCTAssertEqual(post.createdAt.iso8601String, savedPost.createdAt.iso8601String)
                        }
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `query(Post, where: title == post.title)` to check
    ///   if the model was correctly inserted using a predicate
    func testInsertPostAndSelectByTitle() {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        let post = Post(title: "title", content: "content", createdAt: .now())
        storageAdapter.save(post) { saveResult in
            switch saveResult {
            case .success:
                let predicate = Post.keys.title == post.title
                self.storageAdapter.query(Post.self, predicate: predicate) { queryResult in
                    switch queryResult {
                    case .success(let posts):
                        XCTAssertEqual(posts.count, 1)
                        if let savedPost = posts.first {
                            XCTAssert(post.id == savedPost.id)
                            XCTAssert(post.title == savedPost.title)
                            XCTAssert(post.content == savedPost.content)
                            XCTAssertEqual(post.createdAt.iso8601String, savedPost.createdAt.iso8601String)
                        }
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `save(post)` again with an updated title
    ///   - check if the `query(Post)` returns only 1 post
    ///   - the post has the updated title
    func testInsertPostAndThenUpdateIt() {
        let expectation = self.expectation(
            description: "it should insert and update a Post")

        func checkSavedPost(id: String) {
            storageAdapter.query(Post.self) {
                switch $0 {
                case .success(let posts):
                    XCTAssertEqual(posts.count, 1)
                    if let post = posts.first {
                        XCTAssertEqual(post.id, id)
                        XCTAssertEqual(post.title, "title updated")
                    }
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                }
            }
        }

        var post = Post(title: "title", content: "content", createdAt: .now())
        storageAdapter.save(post) { insertResult in
            switch insertResult {
            case .success:
                post.title = "title updated"
                self.storageAdapter.save(post) { updateResult in
                    switch updateResult {
                    case .success:
                        checkSavedPost(id: post.id)
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition)` with `post.title` updated and condition matches `post.content`
    ///    - a successful update for `update(post, condition)`
    ///    - call `query(Post)` to check if the model was correctly updated
    func testInsertPostAndThenUpdateItWithCondition() {
        let expectation = self.expectation(
            description: "it should insert and update a Post")

        func checkSavedPost(id: String) {
            storageAdapter.query(Post.self) {
                switch $0 {
                case .success(let posts):
                    XCTAssertEqual(posts.count, 1)
                    if let post = posts.first {
                        XCTAssertEqual(post.id, id)
                        XCTAssertEqual(post.title, "title updated")
                    }
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                }
            }
        }

        var post = Post(title: "title", content: "content", createdAt: .now())
        storageAdapter.save(post) { insertResult in
            switch insertResult {
            case .success:
                post.title = "title updated"
                let condition = Post.keys.content == post.content
                self.storageAdapter.save(post, condition: condition) { updateResult in
                    switch updateResult {
                    case .success:
                        checkSavedPost(id: post.id)
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post, condition)` is called, condition is passed in.
    /// - Then:
    ///    - Fails with conditional save failed error when there is no existing model instance
    func testUpdateWithConditionFailsWhenNoExistingModel() {
        let expectation = self.expectation(
            description: "it should fail to update the Post that does not exist")

        let post = Post(title: "title", content: "content", createdAt: .now())
        let condition = Post.keys.content == "content"
        storageAdapter.save(post, condition: condition) { insertResult in
            switch insertResult {
            case .success:
                XCTFail("Update should not be successful")
            case .failure(let error):
                guard case .invalidCondition = error else {
                    XCTFail("Did not match invalid condition error")
                    return
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition)` with `post.title` updated and condition does not match
    ///    - the update for `update(post, condition)` fails with conditional save failed error
    func testInsertPostAndThenUpdateItWithConditionDoesNotMatchShouldReturnError() {
        let expectation = self.expectation(
            description: "it should insert and then fail to update the Post, given bad condition")

        var post = Post(title: "title not updated", content: "content", createdAt: .now())
        storageAdapter.save(post) { insertResult in
            switch insertResult {
            case .success:
                post.title = "title updated"
                let condition = Post.keys.content == "content 2 does not match previous content"
                self.storageAdapter.save(post, condition: condition) { updateResult in
                    switch updateResult {
                    case .success:
                        XCTFail("Update should not be successful")
                    case .failure(let error):
                        guard case .invalidCondition = error else {
                            XCTFail("Did not match invalid conditiion")
                            return
                        }

                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `delete(Post, id)` and check if `query(Post)` is empty
    ///   - check if `storageAdapter.exists(Post, id)` returns `false`
    func testInsertPostAndThenDeleteIt() {
        let saveExpectation = expectation(description: "Saved")
        let deleteExpectation = expectation(description: "Deleted")
        let queryExpectation = expectation(description: "Queried")

        let post = Post(title: "title", content: "content", createdAt: .now())
        storageAdapter.save(post) { insertResult in
            switch insertResult {
            case .success:
                saveExpectation.fulfill()
                self.storageAdapter.delete(Post.self, modelSchema: Post.schema, withId: post.id) {
                    switch $0 {
                    case .success:
                        deleteExpectation.fulfill()
                        self.checkIfPostIsDeleted(id: post.id)
                        queryExpectation.fulfill()
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }

        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 2)
    }

    func testInsertSinglePostThenDeleteItByPredicate() {
        let dateTestStart = Temporal.DateTime.now()
        let dateInFuture = dateTestStart + .seconds(10)
        let saveExpectation = expectation(description: "Saved")
        let deleteExpectation = expectation(description: "Deleted")
        let queryExpectation = expectation(description: "Queried")

        let post = Post(title: "title1", content: "content1", createdAt: dateInFuture)
        storageAdapter.save(post) { insertResult in
            switch insertResult {
            case .success:
                saveExpectation.fulfill()
                let postKeys = Post.keys
                let predicate = postKeys.createdAt.gt(dateTestStart)
                self.storageAdapter.delete(Post.self, modelSchema: Post.schema, predicate: predicate) { result in
                    switch result {
                    case .success:
                        deleteExpectation.fulfill()
                        self.checkIfPostIsDeleted(id: post.id)
                        queryExpectation.fulfill()
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }

        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 2)
    }

    func testInsertionOfManyItemsThenDeleteAllByPredicateConstant() {
        let saveExpectation = expectation(description: "Saved 10 items")
        let deleteExpectation = expectation(description: "Deleted 10 items")
        let queryExpectation = expectation(description: "Queried 10 items")

        let titleX = "title"
        let contentX = "content"
        var counter = 0
        let maxCount = 10
        var postsAdded: [String] = []
        while counter < maxCount {
            let title = "\(titleX)\(counter)"
            let content = "\(contentX)\(counter)"

            let post = Post(title: title, content: content, createdAt: .now())
            storageAdapter.save(post) { insertResult in
                switch insertResult {
                case .success:
                    postsAdded.append(post.id)
                    if counter == maxCount - 1 {
                        saveExpectation.fulfill()
                        self.storageAdapter.delete(Post.self,
                                                   modelSchema: Post.schema,
                                                   predicate: QueryPredicateConstant.all) { result in
                            switch result {
                            case .success:
                                deleteExpectation.fulfill()
                                for postId in postsAdded {
                                    self.checkIfPostIsDeleted(id: postId)
                                }
                                queryExpectation.fulfill()
                            case .failure(let error):
                                XCTFail(error.errorDescription)
                            }
                        }
                    }
                case .failure(let error):
                    XCTFail(String(describing: error))
                }
            }
            counter += 1
        }
        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 5)
    }

    func checkIfPostIsDeleted(id: String) {
        do {
            let exists = try storageAdapter.exists(Post.schema, withId: id)
            XCTAssertFalse(exists, "ID \(id) should not exist")
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testClearIfNewVersionWithEmptyUserDefaults() {
        guard let userDefaults = UserDefaults.init(suiteName: "testClearIfNewVersionWithEmptyUserDefaults") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }
        userDefaults.removeObject(forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "newVersion"
        let mockFileManager = MockFileManager()
        mockFileManager.removeItem = { res in
            XCTFail("Should not have called removeItem")
        }

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            XCTFail("Test failed due to \(error)")
        }

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testClearIfNewVersionWithVersionSameAsPrevious() {
        guard let userDefaults = UserDefaults.init(suiteName: "testClearIfNewVersionWithVersionSameAsPrevious") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }
        let previousVersion = "previousVersion"
        userDefaults.set(previousVersion, forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "previousVersion"
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true
        mockFileManager.removeItem = { res in
            XCTFail("Should not have called removeItem")
        }

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            XCTFail("Test failed due to \(error)")
        }

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testClearIfNewVersionWithMissingFile() {
        guard let userDefaults = UserDefaults.init(suiteName: "testClearIfNewVersionWithMissingFile") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "previousVersion"
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true
        mockFileManager.removeItem = { res in
            XCTFail("Should not have called removeItem")
        }

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            XCTFail("Test failed due to \(error)")
        }

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testClearIfNewVersionFailure() {
        guard let userDefaults = UserDefaults.init(suiteName: "testClearIfNewVersionFailure") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "newVersion"
        let mockFileManager = MockFileManager()
        mockFileManager.hasError = true
        mockFileManager.fileExists = true

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            guard let dataStoreError = error as? DataStoreError, case .invalidDatabase = dataStoreError else {
                XCTFail("Expected DataStoreErrorF")
                return
            }
        }

        _ = UserDefaults.removeObject(userDefaults)
    }
}
