//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class DataStoreLocalUsageTests: LocalUsageIntegrationTestBase {

    func testOneSort() throws {
        _ = saveData(num: 20)

        let queryFinished = expectation(description: "Query post completed")
        var posts = [Post]()

        Amplify.DataStore.query(Post.self,
                                sort: .ascending(Post.keys.rating)) { res in
            switch res {
            case .success(let returnPosts):
                posts = returnPosts
                queryFinished.fulfill()
            case .failure(let error):
                XCTFail("Error quering posts, \(error)")
            }
        }
        wait(for: [queryFinished], timeout: 10)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("Retured posts are not in expected order")
            } else {
                previousRating = rating
            }
        }
    }

    func testTwoSorts() throws {
        _ = saveData(num: 50)

        let queryFinished = expectation(description: "Query post completed")
        var posts = [Post]()

        Amplify.DataStore.query(Post.self,
                                sort: .by(.ascending(Post.keys.rating),
                                          .descending(Post.keys.title))) { res in
            switch res {
            case .success(let returnPosts):
                posts = returnPosts
                queryFinished.fulfill()
            case .failure(let error):
                XCTFail("Error quering posts, \(error)")
            }
        }
        wait(for: [queryFinished], timeout: 10)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("Retured posts are not in expected order")
            } else {
                previousRating = rating
            }
        }
        
        // https://developer.apple.com/documentation/swift/dictionary/3127163-init
        let postsDic = Dictionary(grouping: posts, by: { $0.rating! })
        for (_, pairs) in postsDic {
            for index in 0 ..< pairs.count - 1 {
                print(pairs[index].title)
                if pairs[index].title < pairs[index + 1].title {
                    XCTFail("Post titles are not in expected orders")
                }
            }
        }
    }

    func testPredicateAndSort() throws {
        _ = saveData(num: 20)

        let queryFinished = expectation(description: "Query post completed")
        var posts = [Post]()

        Amplify.DataStore.query(Post.self,
                                where: Post.keys.rating >= 2,
                                sort: .ascending(Post.keys.rating)) { res in
            switch res {
            case .success(let returnPosts):
                posts = returnPosts
                queryFinished.fulfill()
            case .failure(let error):
                XCTFail("Error quering posts, \(error)")
            }
        }
        wait(for: [queryFinished], timeout: 10)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("Retured posts are not in expected order")
            } else if rating < 2 {
                XCTFail("Predicate is not working as expected")
            } else {
                previousRating = rating
            }
        }
    }

    func testSortAndPagintate() throws {
        _ = saveData(num: 20)

        let queryFinished = expectation(description: "Query post completed")
        var posts = [Post]()

        Amplify.DataStore.query(Post.self,
                                sort: .by(.ascending(Post.keys.rating),
                                          .descending(Post.keys.title)),
                                paginate: .page(0, limit: 10)) { res in
            switch res {
            case .success(let returnPosts):
                posts = returnPosts
                queryFinished.fulfill()
            case .failure(let error):
                XCTFail("Error quering posts, \(error)")
            }
        }
        wait(for: [queryFinished], timeout: 10)

        XCTAssertTrue(posts.count == 10)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("Retured posts are not in expected order")
            } else {
                previousRating = rating
            }
        }
    }

    func testPredicateAndSortAndPagintate() throws {
        let localPosts = saveData(num: 50)
        let filteredPosts = localPosts.filter { $0.rating! >= 2.0 }
        let count = filteredPosts.count

        let queryFinished = expectation(description: "Query post completed")
        var posts = [Post]()
        Amplify.DataStore.query(Post.self,
                                where: Post.keys.rating >= 2,
                                sort: .ascending(Post.keys.rating),
                                paginate: .page(0, limit: 10)) { res in
            switch res {
            case .success(let returnPosts):
                posts = returnPosts
                queryFinished.fulfill()
            case .failure(let error):
                XCTFail("Error quering posts, \(error)")
            }
        }
        wait(for: [queryFinished], timeout: 10)

        if count >= 10 {
            XCTAssertTrue(posts.count == 10)
        } else {
            XCTAssertTrue(posts.count == count)
        }

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("Retured posts are not in expected order")
            } else if rating < 2 {
                XCTFail("Predicate is not working as expected")
            } else {
                previousRating = rating
            }
        }
    }

    func testSortAndPagintate2() throws {
        _ = saveData(num: 50)

        var count = 0
        Amplify.DataStore.query(Post.self,
                            where: Post.keys.rating >= 2) { res in
            switch res {
            case .success(let returnPosts):
                count = returnPosts.count
            case .failure(let error):
                XCTFail("Error quering posts, \(error)")
            }
        }

        var posts = [Post]()

        var pageNum: UInt = 0
        var shouldRepeat = true
        repeat {
            let queryFinished = expectation(description: "Query post completed")
            Amplify.DataStore.query(Post.self,
                                    where: Post.keys.rating >= 2,
                                    sort: .ascending(Post.keys.rating),
                                    paginate: .page(pageNum, limit: 10)) { res in
                switch res {
                case .success(let returnPosts):
                    posts.append(contentsOf: returnPosts)
                    if returnPosts.count == 10 {
                        pageNum += 1
                    } else {
                        shouldRepeat = false
                    }
                    queryFinished.fulfill()
                case .failure(let error):
                    XCTFail("Error quering posts, \(error)")
                }
            }
            wait(for: [queryFinished], timeout: 10)
        } while shouldRepeat

        XCTAssertTrue(posts.count == count)

        var previousRating: Double = 0
        for post in posts {
            guard let rating = post.rating else {
                XCTFail("Rating should not be nil")
                return
            }
            if rating < previousRating {
                XCTFail("Retured posts are not in expected order")
            } else if rating < 2 {
                XCTFail("Predicate is not working as expected")
            } else {
                previousRating = rating
            }
        }
    }

    func saveData(num: Int) -> [Post] {
        var res = [Post]()
        for _ in 0 ..< num {
            let saveFinished = expectation(description: "Save post completed")
            let post = Post(title: "title\(Int.random(in: 0 ... 5))",
                            content: "content",
                            createdAt: .now(),
                            rating: Double(Int.random(in: 0 ... 5)))
            res.append(post)
            Amplify.DataStore.save(post) { res in
                switch res {
                case .success:
                    saveFinished.fulfill()
                case .failure(let error):
                    XCTFail("Error saving post, \(error)")
                }
            }
            wait(for: [saveFinished], timeout: 10)
        }
        return res
    }
}
