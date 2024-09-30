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

final class S3URLEncodingTests: S3XCTestCase {

    // These are keys with special characters or other edge cases that should be tested against S3 to
    // ensure they work.
    let keys: Set<String> = ["x.txt", "x+x.txt", "x%x.txt", "x x.txt", "abc/x.txt", "abc/x+x.txt", "abc//def//x.txt"]

    func test_putObject_putsAllKeysWithMetadata() async throws {
        for key in keys {
            let input = PutObjectInput(body: .data(Data()), bucket: bucketName, key: key, metadata: ["filename": key])
            _ = try await client.putObject(input: input)
        }
        let createdKeys = Set(try await listBucketKeys())
        XCTAssertTrue(createdKeys.isSuperset(of: keys))
        for key in keys {
            let input = HeadObjectInput(bucket: bucketName, key: key)
            let output = try await client.headObject(input: input)
            XCTAssertEqual(output.metadata?["filename"], key)
        }
    }

    func test_presignedURL_putObject_putsAllKeysWithMetadata() async throws {
        let config = try await S3Client.S3ClientConfiguration(region: region)
        for key in keys {
            let input = PutObjectInput(body: .data(Data()), bucket: bucketName, key: key, metadata: ["filename": key])
            let presignedURLOrNil = try await input.presignURL(config: config, expiration: 30.0)
            let presignedURL = try XCTUnwrap(presignedURLOrNil)
            var urlRequest = URLRequest(url: presignedURL)
            urlRequest.httpMethod = "PUT"
            urlRequest.httpBody = Data()
            _ = try await perform(urlRequest: urlRequest)
        }
        for key in keys {
            let input = HeadObjectInput(bucket: bucketName, key: key)
            let output = try await client.headObject(input: input)
            XCTAssertEqual(output.metadata?["filename"], key)
        }
    }
}
