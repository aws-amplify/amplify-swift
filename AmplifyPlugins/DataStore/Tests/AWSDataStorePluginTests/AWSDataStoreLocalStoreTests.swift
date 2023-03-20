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


    /// Given: 5 `Posts` with titles containing 0...4
    /// When: Querying `Posts` where title`notContains("1")`
    /// Then: 4 posts should be returned, none of which contain `"1"` in the title
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
        XCTAssertEqual(
            posts.count - postsContaining1InTitle.count,
            postsNotContaining1InTitle.count
        )

        XCTAssertTrue(
            postsNotContaining1InTitle.filter(
                { $0.title.contains("1") }
            ).isEmpty
        )
    }


    /// Given: 50 `Posts` with titles containing 0...49
    /// When: Querying posts with multiple `notContains(...)` chained with `&&`
    /// e.g. `notContains(a) && notContains(b)`
    /// Then: Posts returned should not contain either `a` or `b`
    func testQueryMultipleNotContains() async throws {
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: 50)
        let posts = try await Amplify.DataStore.query(Post.self)
        XCTAssertEqual(posts.count, 50)

        let titleValueOne = "25", titleValueTwo = "42"

        let postsContaining25or42InTitle = try await Amplify.DataStore.query(
            Post.self,
            where: Post.keys.title.contains(titleValueOne)
            || Post.keys.title.contains(titleValueTwo)
        )
        XCTAssertEqual(postsContaining25or42InTitle.count, 2)

        let postsNotContaining25or42InTitle = try await Amplify.DataStore.query(
            Post.self,
            where: Post.keys.title.notContains(titleValueOne)
            && Post.keys.title.notContains(titleValueTwo)
        )

        XCTAssertEqual(
            posts.count - postsContaining25or42InTitle.count,
            postsNotContaining25or42InTitle.count
        )

        XCTAssertTrue(
            postsNotContaining25or42InTitle.filter(
                { $0.title.contains(titleValueOne) }
            ).isEmpty
        )

        XCTAssertTrue(
            postsNotContaining25or42InTitle.filter(
                { $0.title.contains(titleValueTwo) }
            ).isEmpty
        )
    }

    /// Given: 50 saved `Post`s
    /// When: Querying for posts with `contains(a)` and `notContains()`
    /// where `a` == `<char in 2 posts>` and `b` == `<status of 1 / 2 posts>`
    /// Then: The result should contain a single `Post` that contains `a` but doesn't contain `b`
    func testQueryNotContainsAndContains() async throws {
        let numberOfPosts = 50
        setUp(withModels: TestModelRegistration())
        _ = try await setUpLocalStore(numberOfPosts: numberOfPosts)
        let posts = try await Amplify.DataStore.query(Post.self)
        XCTAssertEqual(posts.count, numberOfPosts)

        let randomTitleNumber = String(Int.random(in: 0..<numberOfPosts))

        let postWithDuplicateTitleAndDifferentStatus = Post(
            title: "title_\(randomTitleNumber)",
            content: "content",
            createdAt: .now(),
            status: .published
        )

        _ = try await Amplify.DataStore.save(postWithDuplicateTitleAndDifferentStatus)

        let postsContainingRandomTitleNumber = try await Amplify.DataStore.query(
            Post.self,
            where: Post.keys.title.contains(randomTitleNumber)
        )

        XCTAssertEqual(postsContainingRandomTitleNumber.count, 2)
        XCTAssertEqual(
            postsContainingRandomTitleNumber
                .lazy
                .filter({ $0.status == .draft })
                .count,
            1
        )

        XCTAssertEqual(
            postsContainingRandomTitleNumber
                .lazy
                .filter({ $0.status == .published })
                .count,
            1
        )

        let postsContainingRandomTitleNumberAndNotContainingDraftStatus = try await Amplify.DataStore.query(
            Post.self,
            where: Post.keys.title.contains(randomTitleNumber)
            && Post.keys.status.notContains(PostStatus.published.rawValue)
        )

        XCTAssertEqual(
            postsContainingRandomTitleNumberAndNotContainingDraftStatus.count,
            1
        )

        XCTAssertEqual(
            postsContainingRandomTitleNumberAndNotContainingDraftStatus[0].title,
            "title_\(randomTitleNumber)"
        )

        XCTAssertNotEqual(
            postsContainingRandomTitleNumberAndNotContainingDraftStatus[0].status,
            .published
        )
    }

    /// Given: 5 saved `Post`s
    /// When: Deleting with `notContains(a)` where `a` is contained in only one post
    /// Then: All but one `Post` should be deleted. The `Post` containing `a` should remain.
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
        XCTAssertEqual(postsIncluding1InTitle[0].title, "title_1")
    }


    /// Given: 3 saved `Post`s where  2 `Post` titles contain `x` and 1 of those `Post`s content field contain `y`
    /// When: Deleting with `notContains(x) || notContains(y)`. Then querying for remaining `Post`s
    /// Then: The query should return a single `Post` that does **not** contain `x` in the title but **does** contain `y` in the content.
    func testDeleteJoinedOrNotContains() async throws {
        setUp(withModels: TestModelRegistration())

        func post(title: String, content: String) -> Post {
            .init(title: title, content: content, createdAt: .now())
        }

        let post1 = post(title: "title_1", content: "a")
        let post2 = post(title: "title_1", content: "b")
        let post3 = post(title: "title_3", content: "c")

        _ = try await Amplify.DataStore.save(post1)
        _ = try await Amplify.DataStore.save(post2)
        _ = try await Amplify.DataStore.save(post3)

        let posts = try await Amplify.DataStore.query(Post.self)
        XCTAssertEqual(posts.count, 3)

        try await Amplify.DataStore.delete(
            Post.self,
            where: Post.keys.title.notContains("1")
            || Post.keys.content.notContains("a")
        )

        let postsAfterDeletingNotContains1andNotContainsA = try await Amplify.DataStore.query(Post.self)
        XCTAssertEqual(postsAfterDeletingNotContains1andNotContainsA.count, 1)
        XCTAssertEqual(postsAfterDeletingNotContains1andNotContainsA[0].content, "a")
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
