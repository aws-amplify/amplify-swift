//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// swfitlint:disable file_length
// swiftlint:disable type_body_length
class DataStoreLocalStoreTests: LocalStoreIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
            registry.register(modelType: Comment.self)
        }

        let version: String = "1"
    }

    /// - Given: 4 posts that has been saved
    /// - When:
    ///    - query with grouped predicate
    /// - Then:
    ///    - 2 post instances will be returned
    ///    - second page returns the remaining 5 posts
    ///    - the 15 retrieved posts have unique identifiers
    func testQueryWithGroupedQueryPredicateInput() throws {
        setUp(withModels: TestModelRegistration())
        setUpLocalStoreForGroupedPredicateTest()
        var posts = [Post]()
        let queryFirstTimeSuccess = expectation(description: "Query post completed")
        let post = Post.keys
        let predicate = (post.id <= 1 && post.title == "title1")
            || (post.rating > 2 && post.status == PostStatus.private)
        Amplify.DataStore.query(Post.self,
                                where: predicate) { result in
            switch result {
            case .success(let returnPosts):
                posts.append(contentsOf: returnPosts)
                queryFirstTimeSuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [queryFirstTimeSuccess], timeout: 10)

        XCTAssertEqual(posts.count, 2)
    }

    /// - Given: 15 posts that has been saved
    /// - When:
    ///    - query with pagination input given a page number and limit 10
    /// - Then:
    ///    - first page returns the 10 (the defined limit) of 15 posts
    ///    - second page returns the remaining 5 posts
    ///    - the 15 retrieved posts have unique identifiers
    func testQueryWithPaginationInput() throws {
        setUp(withModels: TestModelRegistration())
        _ = setUpLocalStore(numberOfPosts: 15)
        var posts = [Post]()
        let queryFirstTimeSuccess = expectation(description: "Query post completed")

        Amplify.DataStore.query(Post.self,
                                paginate: .page(0, limit: 10)) { result in
            switch result {
            case .success(let returnPosts):
                posts.append(contentsOf: returnPosts)
                queryFirstTimeSuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [queryFirstTimeSuccess], timeout: 10)

        XCTAssertEqual(posts.count, 10)

        let querySecondTimeSuccess = expectation(description: "Query post completed")
        Amplify.DataStore.query(Post.self,
                                paginate: .page(1, limit: 10)) { result in
            switch result {
            case .success(let returnPosts):
                posts.append(contentsOf: returnPosts)
                querySecondTimeSuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [querySecondTimeSuccess], timeout: 10)

        XCTAssertEqual(posts.count, 15)

        let idSet = Set(posts.map { $0.id })

        XCTAssertEqual(idSet.count, 15)
    }

    /// - Given: 20 posts that has been saved
    /// - When:
    ///    - attempt to query existing posts that are sorted by rating in ascending order
    /// - Then:
    ///    - the existing data will be returned in expected order
    func testQueryWithSortReturnsPostsInAscendingOrder() throws {
        setUp(withModels: TestModelRegistration())
        _ = setUpLocalStore(numberOfPosts: 20)

        let querySuccess = expectation(description: "Query post completed")
        var posts = [Post]()

        Amplify.DataStore.query(Post.self,
                                sort: .ascending(Post.keys.rating)) { result in
            switch result {
            case .success(let returnPosts):
                posts = returnPosts
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [querySuccess], timeout: 10)

        XCTAssertEqual(posts.count, 20)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("ratings should be in ascending order")
            } else {
                previousRating = rating
            }
        }
    }

    /// - Given: 50 posts that has been saved
    /// - When:
    ///    - attempt to query existing posts firstly sorted by rating in ascending order and secondly sorted by title in descending order
    /// - Then:
    ///    - the existing data will be returned in expected order
    func testQueryWithMultipleSortsReturnsPosts() throws {
        setUp(withModels: TestModelRegistration())
        _ = setUpLocalStore(numberOfPosts: 50)

        let querySuccess = expectation(description: "Query post completed")
        var posts = [Post]()

        Amplify.DataStore.query(Post.self,
                                sort: .by(.ascending(Post.keys.rating),
                                          .descending(Post.keys.title))) { result in
            switch result {
            case .success(let returnPosts):
                posts = returnPosts
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [querySuccess], timeout: 10)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("ratings should be in ascending order")
            } else {
                previousRating = rating
            }
        }

        // Group the posts by the first sort field, rating. By using `Dictionary(grouping:by:)`,
        // the values in each grouop will be the same order as the original Post array
        // See https://developer.apple.com/documentation/swift/dictionary/3127163-init for more details
        let postsDic = Dictionary(grouping: posts, by: { $0.rating! })
        for (_, pairs) in postsDic {
            for index in 0 ..< pairs.count - 1 {
                if pairs[index].title < pairs[index + 1].title {
                    XCTFail("title should be in descending order")
                }
            }
        }
    }

    /// - Given: 20 posts that has been saved
    /// - When:
    ///    - attempt to query existing posts matching a condition and sorted by rating in ascending order
    /// - Then:
    ///    - the existing data that matches the given condition will be returned in ascending order by rating
    func testQueryWithPredicateAndSort() throws {
        setUp(withModels: TestModelRegistration())
        _ = setUpLocalStore(numberOfPosts: 20)

        let querySuccess = expectation(description: "Query post completed")
        var posts = [Post]()

        Amplify.DataStore.query(Post.self,
                                where: Post.keys.rating >= 2,
                                sort: .ascending(Post.keys.rating)) { result in
            switch result {
            case .success(let returnPosts):
                posts = returnPosts
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [querySuccess], timeout: 10)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < 2 {
                XCTFail("Predicate is not working as expected")
            }
            if rating < previousRating {
                XCTFail("ratings should be in ascending order")
            } else {
                previousRating = rating
            }
        }
    }

    /// - Given: 20 posts that has been saved
    /// - When:
    ///    - attempt to query the first 10 existing posts that are sorted by rating in ascending order
    /// - Then:
    ///    - the existing data that matches the given condition will be returned in ascending order by rating
    func testQueryWithSortAndPagintate() throws {
        setUp(withModels: TestModelRegistration())
        _ = setUpLocalStore(numberOfPosts: 20)

        let querySuccess = expectation(description: "Query post completed")
        var posts = [Post]()

        Amplify.DataStore.query(Post.self,
                                sort: .by(.ascending(Post.keys.rating),
                                          .descending(Post.keys.title)),
                                paginate: .page(0, limit: 10)) { result in
            switch result {
            case .success(let returnPosts):
                posts = returnPosts
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [querySuccess], timeout: 10)

        XCTAssertEqual(posts.count, 10)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("ratings should be in ascending order")
            } else {
                previousRating = rating
            }
        }
    }

    /// - Given: 50 posts that has been saved
    /// - When:
    ///    - attempt to query the first 10 existing posts that mathches a condition and are sorted by rating in ascending order
    /// - Then:
    ///    - 10 or less existing data that matches the given condition will be returned in ascending order by rating
    func testQueryWithPredicateAndSortAndPagintate() throws {
        setUp(withModels: TestModelRegistration())
        let localPosts = setUpLocalStore(numberOfPosts: 50)
        let filteredPosts = localPosts.filter { $0.rating! >= 2.0 }
        let count = filteredPosts.count

        let querySuccess = expectation(description: "Query post completed")
        var posts = [Post]()
        Amplify.DataStore.query(Post.self,
                                where: Post.keys.rating >= 2,
                                sort: .ascending(Post.keys.rating),
                                paginate: .page(0, limit: 10)) { result in
            switch result {
            case .success(let returnPosts):
                posts = returnPosts
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [querySuccess], timeout: 10)

        if count >= 10 {
            XCTAssertEqual(posts.count, 10)
        } else {
            XCTAssertEqual(posts.count, count)
        }

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < 2 {
                XCTFail("Predicate is not working as expected")
            }
            if rating < previousRating {
                XCTFail("ratings should be in ascending order")
            } else {
                previousRating = rating
            }
        }
    }

    /// - Given: 50 posts that has been saved
    /// - When:
    ///    - attempt to query the every existing posts that mathches a condition and are sorted by rating in ascending order
    /// - Then:
    ///    - the existing data that matches the given condition will be returned in ascending order by rating
    func testQueryWithPredicateAndSortWithMultiplePages() throws {
        setUp(withModels: TestModelRegistration())
        _ = setUpLocalStore(numberOfPosts: 50)

        var count = 0
        Amplify.DataStore.query(Post.self,
                                where: Post.keys.rating >= 2) { result in
            switch result {
            case .success(let returnPosts):
                count = returnPosts.count
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }

        var posts = [Post]()
        var currentPage: UInt = 0
        var shouldRepeat = true
        repeat {
            let querySuccess = expectation(description: "Query post completed")
            Amplify.DataStore.query(Post.self,
                                    where: Post.keys.rating >= 2,
                                    sort: .ascending(Post.keys.rating),
                                    paginate: .page(currentPage, limit: 10)) { result in
                switch result {
                case .success(let returnPosts):
                    posts.append(contentsOf: returnPosts)
                    if returnPosts.count == 10 {
                        currentPage += 1
                    } else {
                        shouldRepeat = false
                    }
                    querySuccess.fulfill()
                case .failure(let error):
                    XCTFail("Error querying posts: \(error)")
                }
            }
            wait(for: [querySuccess], timeout: 10)
        } while shouldRepeat

        XCTAssertEqual(posts.count, count)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < 2 {
                XCTFail("Predicate is not working as expected")
            }
            if rating < previousRating {
                XCTFail("ratings should be in ascending order")
            } else {
                previousRating = rating
            }
        }
    }

    /// DataStore without sync to cloud enabled.
    ///
    /// - Given: DataStore is set up with models, and local store is populated with models
    /// - When:
    ///    - ObserveQuery is called, add more models
    /// - Then:
    ///    - The first snapshot will have initial models and may have additional models
    ///    - There may be subsequent snapshots based on how the items are batched
    ///    - The last snapshot will have a total of initial plus additional models
    @available(iOS 13.0, *)
    func testObserveQuery() throws {
        setUp(withModels: TestModelRegistration())
        let cleared = expectation(description: "DataStore cleared")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                cleared.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [cleared], timeout: 2)
        _ = setUpLocalStore(numberOfPosts: 15)
        var snapshotCount = 0
        let allSnapshotsReceived = expectation(description: "query snapshots received")

        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            snapshotCount += 1
            XCTAssertFalse(querySnapshot.isSynced)
            if querySnapshot.items.count == 30 {
                allSnapshotsReceived.fulfill()
            }
        }
        _ = setUpLocalStore(numberOfPosts: 15)
        wait(for: [allSnapshotsReceived], timeout: 100)
        XCTAssertTrue(snapshotCount >= 2)
        sink.cancel()
    }

    func testDeleteModelTypeWithPredicate() {
        setUp(withModels: TestModelRegistration())
        _ = setUpLocalStore(numberOfPosts: 5)
        let queryOnSetUpSuccess = expectation(description: "query returns non-empty result")
        Amplify.DataStore.query(Post.self, where: Post.keys.status.eq(PostStatus.draft)) { result in
            switch result {
            case .success(let posts):
                XCTAssertFalse(posts.isEmpty)
                queryOnSetUpSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [queryOnSetUpSuccess], timeout: 1)
        let deleteSuccess = expectation(description: "Delete all successful")
        Amplify.DataStore.delete(Post.self, where: Post.keys.status.eq(PostStatus.draft)) { result in
            switch result {
            case .success:
                deleteSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteSuccess], timeout: 1)

        let queryComplete = expectation(description: "query returns empty result")
        Amplify.DataStore.query(Post.self, where: Post.keys.status.eq(PostStatus.draft)) { result in
            switch result {
            case .success(let posts):
                XCTAssertEqual(posts.count, 0)
                queryComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [queryComplete], timeout: 1)
    }

    func testDeleteAll() {
        setUp(withModels: TestModelRegistration())
        _ = setUpLocalStore(numberOfPosts: 5)
        let deleteSuccess = expectation(description: "Delete all successful")
        Amplify.DataStore.delete(Post.self, where: QueryPredicateConstant.all) { result in
            switch result {
            case .success:
                deleteSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteSuccess], timeout: 1)

        let queryComplete = expectation(description: "query returns empty result")
        Amplify.DataStore.query(Post.self) { result in
            switch result {
            case .success(let posts):
                XCTAssertEqual(posts.count, 0)
                queryComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [queryComplete], timeout: 1)
    }

    func setUpLocalStore(numberOfPosts: Int) -> [Post] {
        var savedPosts = [Post]()
        for id in 0 ..< numberOfPosts {
            let saveSuccess = expectation(description: "Save post completed")
            let post = Post(title: "title\(Int.random(in: 0 ... 5))",
                            content: "content",
                            createdAt: .now(),
                            rating: Double(Int.random(in: 0 ... 5)),
                            status: .draft)
            savedPosts.append(post)
            print("\(id) \(post.id)")
            Amplify.DataStore.save(post) { result in
                switch result {
                case .success:
                    saveSuccess.fulfill()
                case .failure(let error):
                    XCTFail("Error saving post, \(error)")
                }
            }
            wait(for: [saveSuccess], timeout: 10)
        }

        return savedPosts
    }

    func setUpLocalStoreForGroupedPredicateTest() {
        var savedPosts = [Post]()
        savedPosts.append(Post(id: "1", title: "title1", content: "content1",
                               createdAt: .now(), rating: 1, status: .draft))
        savedPosts.append(Post(id: "2", title: "title2", content: "content2",
                               createdAt: .now(), rating: 2, status: .private))
        savedPosts.append(Post(id: "3", title: "title3", content: "content3",
                               createdAt: .now(), rating: 3, status: .draft))
        savedPosts.append(Post(id: "4", title: "title4", content: "content4",
                               createdAt: .now(), rating: 4, status: .private))
        for post in savedPosts {
            let saveSuccess = expectation(description: "Save post completed")
            Amplify.DataStore.save(post) { result in
                switch result {
                case .success:
                    saveSuccess.fulfill()
                case .failure(let error):
                    XCTFail("Error saving post, \(error)")
                }
            }
            wait(for: [saveSuccess], timeout: 10)
        }
    }
}
