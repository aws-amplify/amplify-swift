//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore
import AmplifyTestCommon

@testable import Amplify
@testable import AWSDataStorePlugin


// swfitlint:disable file_length
// swiftlint:disable type_body_length
class AWSDataStoreLocalStoreTests: LocalStoreIntegrationTestBase {

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
    func testQueryWithGroupedQueryPredicateInput() async throws {
        setUp(withModels: TestModelRegistration())
        try await setUpLocalStoreForGroupedPredicateTest()
        let post = Post.keys
        let predicate = (post.id <= 1 && post.title == "title1")
            || (post.rating > 2 && post.status == PostStatus.private)
        
        let queriedPosts = try await Amplify.DataStore.query(Post.self, where: predicate)
        XCTAssertEqual(queriedPosts.count, 2)
    }

    /// - Given: 15 posts that has been saved
    /// - When:
    ///    - query with pagination input given a page number and limit 10
    /// - Then:
    ///    - first page returns the 10 (the defined limit) of 15 posts
    ///    - second page returns the remaining 5 posts
    ///    - the 15 retrieved posts have unique identifiers
    func testQueryWithPaginationInput() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 15)
        var posts = [Post]()
        let queriedPosts = try await Amplify.DataStore.query(Post.self, paginate: .page(0, limit: 10))
        XCTAssertEqual(queriedPosts.count, 10)
        posts.append(contentsOf: queriedPosts)
        
        let queriedPosts2 = try await Amplify.DataStore.query(Post.self, paginate: .page(1, limit: 10))
        XCTAssertEqual(queriedPosts2.count, 5)
        posts.append(contentsOf: queriedPosts2)
        
        let idSet = Set(posts.map { $0.id })
        XCTAssertEqual(idSet.count, 15)
    }

    /// - Given: 20 posts that has been saved
    /// - When:
    ///    - attempt to query existing posts that are sorted by rating in ascending order
    /// - Then:
    ///    - the existing data will be returned in expected order
    func testQueryWithSortReturnsPostsInAscendingOrder() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 20)

        let posts = try await Amplify.DataStore.query(Post.self, sort: .ascending(Post.keys.rating))
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
    func testQueryWithMultipleSortsReturnsPosts() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 50)

        let posts = try await Amplify.DataStore.query(Post.self,
                                                      sort: .by(.ascending(Post.keys.rating),
                                                                .descending(Post.keys.title)))
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
    func testQueryWithPredicateAndSort() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 20)

        let posts = try await Amplify.DataStore.query(Post.self,
                                                      where: Post.keys.rating >= 2,
                                                      sort: .ascending(Post.keys.rating))

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
    func testQueryWithSortAndPagintate() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 20)
        let posts = try await Amplify.DataStore.query(Post.self,
                                                      sort: .by(.ascending(Post.keys.rating),
                                                                .descending(Post.keys.title)),
                                                      paginate: .page(0, limit: 10))
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
    func testQueryWithPredicateAndSortAndPagintate() async throws {
        setUp(withModels: TestModelRegistration())
        let localPosts = try await setUpLocalStore(numberOfPosts: 50)
        let filteredPosts = localPosts.filter { $0.rating! >= 2.0 }
        let count = filteredPosts.count

        let posts = try await Amplify.DataStore.query(Post.self,
                                                      where: Post.keys.rating >= 2,
                                                      sort: .ascending(Post.keys.rating),
                                                      paginate: .page(0, limit: 10))
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
    func testQueryWithPredicateAndSortWithMultiplePages() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 50)

        let queriedPosts = try await Amplify.DataStore.query(Post.self,
                                                      where: Post.keys.rating >= 2)
            
        var posts = [Post]()
        var currentPage: UInt = 0
        var shouldRepeat = true
        repeat {
            let returnPosts = try await Amplify.DataStore.query(Post.self,
                                                                where: Post.keys.rating >= 2,
                                                                sort: .ascending(Post.keys.rating),
                                                                paginate: .page(currentPage, limit: 10))
            posts.append(contentsOf: returnPosts)
            if returnPosts.count == 10 {
                currentPage += 1
            } else {
                shouldRepeat = false
            }
        } while shouldRepeat

        XCTAssertEqual(posts.count, queriedPosts.count)

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
    func testObserveQuery() async throws {
        setUp(withModels: TestModelRegistration())
        try await Amplify.DataStore.clear()
        var snapshotCount = 0
        let initialQueryComplete = asyncExpectation(description: "initial snapshot received")
        let allSnapshotsReceived = asyncExpectation(description: "query snapshots received")

        let subscription = Amplify.DataStore.observeQuery(for: Post.self)
        let sink = Amplify.Publisher.create(subscription).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            snapshotCount += 1
            if snapshotCount == 1 {
                Task { await initialQueryComplete.fulfill() }
            }
            if querySnapshot.items.count == 15 {
                Task { await allSnapshotsReceived.fulfill() }
            }
        }
        await waitForExpectations([initialQueryComplete], timeout: 10)
        _ = try await setUpLocalStore(numberOfPosts: 15)
        await waitForExpectations([allSnapshotsReceived], timeout: 10)
        XCTAssertTrue(snapshotCount >= 2)
        sink.cancel()
    }

    func testDeleteModelTypeWithPredicate() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 5)
        var posts = try await Amplify.DataStore.query(Post.self, where: Post.keys.status.eq(PostStatus.draft))
        XCTAssertFalse(posts.isEmpty)
        _ = try await Amplify.DataStore.delete(Post.self, where: Post.keys.status.eq(PostStatus.draft))
        posts = try await Amplify.DataStore.query(Post.self, where: Post.keys.status.eq(PostStatus.draft))
        XCTAssertEqual(posts.count, 0)
    }

    func testDeleteAll() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 5)
        _ = try await Amplify.DataStore.delete(Post.self, where: QueryPredicateConstant.all)
        let posts = try await Amplify.DataStore.query(Post.self)
        XCTAssertEqual(posts.count, 0)
    }

    func testQueryNotContains() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 5)
        let posts = try await Amplify.DataStore.query(Post.self)
        XCTAssertEqual(posts.count, 5)

        let postsContaining1InTitle = try await Amplify.DataStore.query(
            Post.self,
            where: Post.keys.title.contains("1")
        )
        XCTAssertEqual(postsContaining1InTitle.count, 1)

        let postsNotContaining1InTitle = try await Amplify.DataStore.query(
            Post.self,
            where: Post.keys.title.notContains("1")
        )
        XCTAssertEqual(postsNotContaining1InTitle.count, 4)
    }


    func testDeleteNotContains() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 5)
        let posts = try await Amplify.DataStore.query(Post.self)
        XCTAssertEqual(posts.count, 5)

        try await Amplify.DataStore.delete(
            Post.self,
            where: Post.keys.title.notContains("1")
        )

        let postsIncluding1InTitle = try await Amplify.DataStore.query(Post.self)
        XCTAssertEqual(postsIncluding1InTitle.count, 1)
    }


    func setUpLocalStore(numberOfPosts: Int) async throws -> [Post] {
        let posts = (0..<numberOfPosts).map {
            Post(
                title: "title_\($0)",
                content: "content",
                createdAt: .now(),
                rating: Double(Int.random(in: 0 ... 5)),
                status: .draft
            )
        }

        for (index, post) in posts.enumerated() {
            print("\(index) \(post.id)")
            try await Amplify.DataStore.save(post)
        }

        return posts
    }

    func setUpLocalStoreForGroupedPredicateTest() async throws {
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
            _ = try await Amplify.DataStore.save(post)
        }
    }
}
