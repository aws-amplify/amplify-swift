//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
import AWSS3

/// Provides a basic set of functions that can be used to perform S3 integration tests.
/// Creates a bucket for testing before every test, then deletes the bucket after the test completes.
class S3XCTestCase: XCTestCase {
    static var client: S3Client!
    static let region = "us-west-2"
    var client: S3Client { Self.client }
    var region: String { Self.region }
    var bucketName: String!

    struct HTTPError: Error, CustomDebugStringConvertible {
        let code: Int
        let data: Data
        let urlString: String

        init(code: Int, data: Data?, url: URL?) {
            self.code = code
            self.data = data ?? Data()
            self.urlString = url?.absoluteString ?? "<no URL>"
        }

        var debugDescription: String {
            let bodyString = String(data: data, encoding: .utf8) ?? "<not a string>"
            return "HTTP request to: \(urlString) failed with code: \(code), body: \(bodyString)"
        }
    }

    override func setUp() async throws{
        self.bucketName = "aws-sdk-s3-integration-test-\(UUID().uuidString.split(separator: "-").first!.lowercased())"
        Self.client = try S3Client(region: region)
        try await Self.createBucket(bucketName: bucketName)
    }

    /// Empty & delete the test bucket before each test.
    override func tearDown() async throws {
        try await emptyBucket()
        try await Self.deleteBucket(bucketName: bucketName)
    }

    // MARK: Helpers

    /// Performs a URL request using URLSession.
    ///
    /// Useful for testing presigned URLs.
    /// - Parameter urlRequest: The urlRequest to be performed.
    /// - Returns: The data from the request, or empty data if the request has no body.
    /// - Throws: Any error returned by the data task, or `HTTPError` if the request completes and the HTTP status code is not 200 series.
    func perform(urlRequest: URLRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: urlRequest) { data, urlResponse, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let code = (urlResponse as? HTTPURLResponse)?.statusCode, !(200...299).contains(code) {
                    let error = HTTPError(code: code, data: data, url: urlRequest.url)
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data ?? Data())
                }
            }
            task.resume()
        }
    }

    static func createBucket(bucketName: String) async throws {
        let input = CreateBucketInput(bucket: bucketName, createBucketConfiguration: S3ClientTypes.CreateBucketConfiguration(locationConstraint: S3ClientTypes.BucketLocationConstraint.usWest2))
        _ = try await Self.client.createBucket(input: input)
    }

    func putObject(body: String, key: String) async throws {
        let input = PutObjectInput(body: .data(body.data(using: .utf8)), bucket: bucketName, key: key)
        _ = try await client.putObject(input: input)
    }

    func getObject(key: String) async throws -> String? {
        let input = GetObjectInput(bucket: bucketName, key: key)
        let output = try await client.getObject(input: input)
        let body = try XCTUnwrap(output.body)
        switch body {
        case .data(let dataOrNil):
            let data = try XCTUnwrap(dataOrNil)
            return String(data: data, encoding: .utf8)
        case .stream(let stream):
            return String(data: try await stream.readToEndAsync() ?? Data(), encoding: .utf8)
        case .noStream:
            return nil
        }
    }

    func listBucketKeys() async throws -> Set<String> {
        let input = ListObjectsV2Input(bucket: bucketName)
        let output = try await client.listObjectsV2(input: input)
        return Set(output.contents?.compactMap { $0.key } ?? [])
    }

    func emptyBucket() async throws {
        let keys = try await listBucketKeys()
        for key in keys {
            let deleteInput = DeleteObjectInput(bucket: bucketName, key: key)
            _ = try await client.deleteObject(input: deleteInput)
        }
    }

    static func deleteBucket(bucketName: String) async throws {
        let input = DeleteBucketInput(bucket: bucketName)
        _ = try await client.deleteBucket(input: input)
    }
}
