//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import Amplify
import XCTest

@testable import AWSS3StoragePlugin

final class StorageListingTests: XCTestCase {

    var client: MockS3Client!
    var bucket: String!
    var prefix: String!
    var input: ListObjectsV2Input!

    override func setUp() async throws {
        client = MockS3Client()
        bucket = UUID().uuidString
        prefix = "public/\(UUID())/"
        input = ListObjectsV2Input(bucket: bucket, prefix: prefix)
    }

    override func tearDown() async throws {
        client = nil
        bucket = nil
        prefix = nil
        input = nil
    }

    /// Given: An S3 bucket containing two-pages worth of keys
    /// When: A `StorageListing` is created using typical parameter values
    /// Then: The resulting iterator returns non-nil values for `next()` twice followed by `nil`
    func testClientTwoPages() async throws {
        let first = createRandomObject()
        let last = createRandomObject()
        let nextContinuationToken = UUID().uuidString
        var responses = [
            ListObjectsV2OutputResponse(contents: [first], nextContinuationToken: nextContinuationToken),
            ListObjectsV2OutputResponse(contents: [last], nextContinuationToken: nil),
        ]
        client.listObjectsV2Handler = { _ in
            let result = responses[0]
            responses.removeFirst()
            return result
        }

        var listing = try await StorageListing.create(with: client, prefix: prefix, input: input)

        let firstFileName = try XCTUnwrap((first.key as? NSString)?.lastPathComponent)
        let lastFileName = try XCTUnwrap((last.key as? NSString)?.lastPathComponent)
        let normalizedKeys = try await listing.firstPage().map { $0.key }
        XCTAssertEqual(normalizedKeys, [firstFileName])

        let sequence = listing.itemSequence
        var iterator = sequence.makeAsyncIterator()

        let firstPageOrNil = try await iterator.next()
        let firstPage = try XCTUnwrap(firstPageOrNil)
        XCTAssertEqual(firstPage.map { $0.key }, [firstFileName])

        let lastPageOrNil = try await iterator.next()
        let lastPage = try XCTUnwrap(lastPageOrNil)
        XCTAssertEqual(lastPage.map { $0.key }, [lastFileName])

        let nilPage = try await iterator.next()
        XCTAssertNil(nilPage)

        XCTAssertEqual(client.interactions, [
            "listObjectsV2(input:) bucket: \(bucket ?? "nil") prefix: \(prefix ?? "nil") continuationToken: nil",
            "listObjectsV2(input:) bucket: \(bucket ?? "nil") prefix: \(prefix ?? "nil") continuationToken: \(nextContinuationToken)",
        ])
    }

    /// Given: An S3 bucket containing two-pages worth of keys
    /// When: A `StorageListing` is created using typical parameter values
    /// Then: The resulting sequence can be iterated to list all keys.
    func testClientTwoPagesFlatMap() async throws {
        let first = createRandomObject()
        let last = createRandomObject()
        let nextContinuationToken = UUID().uuidString
        var responses = [
            ListObjectsV2OutputResponse(contents: [first], nextContinuationToken: nextContinuationToken),
            ListObjectsV2OutputResponse(contents: [last], nextContinuationToken: nil),
        ]
        client.listObjectsV2Handler = { _ in
            let result = responses[0]
            responses.removeFirst()
            return result
        }

        var listing = try await StorageListing.create(with: client, prefix: prefix, input: input)

        let firstFileName = try XCTUnwrap((first.key as? NSString)?.lastPathComponent)
        let lastFileName = try XCTUnwrap((last.key as? NSString)?.lastPathComponent)
        let normalizedKeys = try await listing.firstPage().map { $0.key }
        XCTAssertEqual(normalizedKeys, [firstFileName])

        let paginatedKeys = try await flatMap(sequence: listing.itemSequence) { page in
            return page.map { $0.key }
        }
        XCTAssertEqual(paginatedKeys, [
            firstFileName,
            lastFileName
        ])

        XCTAssertEqual(client.interactions, [
            "listObjectsV2(input:) bucket: \(bucket ?? "nil") prefix: \(prefix ?? "nil") continuationToken: nil",
            "listObjectsV2(input:) bucket: \(bucket ?? "nil") prefix: \(prefix ?? "nil") continuationToken: \(nextContinuationToken)",
        ])
    }

    func createRandomObject() -> S3ClientTypes.Object {
        return .init(
            checksumAlgorithm: [.sha256],
            eTag: UUID().uuidString,
            key: prefix + UUID().uuidString,
            lastModified: Date(),
            owner: .none,
            size: Int.random(in: 0..<1024),
            storageClass: .standard
        )
    }

    /// Given: An S3 bucket containing a single key
    /// When: A `StorageListing` is created using typical parameter values
    /// Then: The resulting first page and sequence resolve to that single key
    func testClientSingleItem() async throws {
        let object = createRandomObject()
        client.listObjectsV2Handler = { _ in
            return .init(
                contents: [object],
                nextContinuationToken: nil
            )
        }
        var listing = try await StorageListing.create(with: client, prefix: prefix, input: input)
        let objectFileName = try XCTUnwrap((object.key as? NSString)?.lastPathComponent)
        let normalizedKeys = try await listing.firstPage().map { $0.key }
        XCTAssertEqual(normalizedKeys, [objectFileName])

        let paginatedKeys = try await flatMap(sequence: listing.itemSequence) { page in
            return page.map { $0.key }
        }
        XCTAssertEqual(paginatedKeys, [objectFileName])
        XCTAssertEqual(client.interactions, [
            "listObjectsV2(input:) bucket: \(bucket ?? "nil") prefix: \(prefix ?? "nil") continuationToken: nil"
        ])
    }
    
    func flatMap<Output>(sequence: StorageItemPageSequence,
                     _ transform: ([StorageListResult.Item]) -> [Output]) async throws -> [Output] {
        var result: [Output] = []
        for try await original in sequence {
            let transformed: [Output] = transform(original)
            result.append(contentsOf: transformed)
        }
        return result
    }
    
    /// Given: A bug that throws an error in the internals of the S3 client
    /// When: An attempt to create a`StorageListing` using typical parameter values is made
    /// Then: The error is propagated to the caller
    func testClientFailureExpected() async throws {
        enum ClientError: Error { case expectedError }
        client.listObjectsV2Handler = { _ in
            throw ClientError.expectedError
        }
        do {
            let _ = try await StorageListing.create(with: client, prefix: prefix, input: .init())
            XCTFail("Expecting client error")
        } catch {
            XCTAssertEqual(String(describing: error), "expectedError")
        }
        XCTAssertEqual(client.interactions, [
            "listObjectsV2(input:) bucket: nil prefix: nil continuationToken: nil"
        ])
    }

    /// Given: An latent error from the S3 client
    /// When: An attempt to create a`StorageListing` using typical parameter values is made
    /// Then: The error is propagated to the caller
    func testClientFailureOnFirstAttempt() async throws {
        do {
            let _ = try await StorageListing.create(with: client, prefix: "", input: .init())
            XCTFail("Expecting client error")
        } catch {
            XCTAssertEqual(String(describing: error), "missingResult")
        }
        XCTAssertEqual(client.interactions, [
            "listObjectsV2(input:) bucket: nil prefix: nil continuationToken: nil"
        ])
    }
}
