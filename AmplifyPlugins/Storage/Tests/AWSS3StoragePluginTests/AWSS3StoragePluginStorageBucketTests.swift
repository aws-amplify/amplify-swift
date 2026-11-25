//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import InternalAmplifyCredentials
import XCTest
@testable import Amplify
@testable import AWSPluginsTestCommon
@testable import AWSS3StoragePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSS3StoragePluginStorageBucketTests: XCTestCase, @unchecked Sendable {
    private var storagePlugin: AWSS3StoragePlugin!
    private var defaultService: MockAWSS3StorageService!
    private var authService: MockAWSAuthService!
    private var queue: OperationQueue!
    private let defaultBucketInfo = BucketInfo(
        bucketName: "bucketName",
        region: "us-east-1"
    )
    private let additionalBucketInfo = BucketInfo(
        bucketName: "anotherBucketName",
        region: "us-east-2"
    )

    private var additionalS3Bucket: AmplifyOutputsData.Storage.Bucket {
        return .init(
            name: "anotherBucket",
            bucketName: additionalBucketInfo.bucketName,
            awsRegion: additionalBucketInfo.region
        )
    }

    override func setUp() {
        storagePlugin = AWSS3StoragePlugin()
        defaultService = MockAWSS3StorageService()
        authService = MockAWSAuthService()
        queue = OperationQueue()
        storagePlugin.configure(
            defaultBucket: .fromBucketInfo(defaultBucketInfo),
            storageService: defaultService,
            authService: authService,
            defaultAccessLevel: .guest,
            queue: queue
        )
    }

    override func tearDown() async throws {
        try await Task.sleep(seconds: 0.1) // This is unfortunate but necessary to give the DB time to recover the URLSession tasks
        await storagePlugin.reset()
        queue.cancelAllOperations()
        storagePlugin = nil
        defaultService = nil
        authService = nil
        queue = nil
    }

    /// Given: A configured AWSS3StoragePlugin
    /// When: storageService(for:) is invoked with nil
    /// Then: The default storage service should be returned
    func testStorageService_withNil_shouldReturnDefaultService() throws {
        let storageService = try storagePlugin.storageService(for: nil)
        guard let mockService = storageService as? MockAWSS3StorageService else {
            XCTFail("Expected a MockAWSS3StorageService, got \(type(of: storageService))")
            return
        }
        XCTAssertTrue(mockService === defaultService)
    }

    /// Given: A AWSS3StoragePlugin configured with additional bucket names
    /// When: storageService(for:) is invoked with .fromOutputs with an existing value
    /// Then: A valid AWSS3StorageService should be returned pointing to that bucket
    func testStorageService_withBucketFromOutputs_shouldReturnStorageService() throws {
        storagePlugin.additionalBucketsByName = [
            additionalS3Bucket.name: additionalS3Bucket
        ]
        let storageService = try storagePlugin.storageService(for: .fromOutputs(name: additionalS3Bucket.name))
        guard let newService = storageService as? AWSS3StorageService else {
            XCTFail("Expected a AWSS3StorageService, got \(type(of: storageService))")
            return
        }
        XCTAssertFalse(newService === defaultService)
        XCTAssertEqual(newService.bucket, additionalS3Bucket.bucketName)
    }

    /// Given: A AWSS3StoragePlugin configured without additional buckets (i.e. no AmplifyOutputs)
    /// When: storageService(for:) is invoked with .fromOutputs
    /// Then: A StorageError.validation error is thrown
    func testStorageService_withBucketFromOutputs_withoutConfiguringOutputs_shouldThrowValidationException() {
        storagePlugin.additionalBucketsByName = nil
        do {
            _ = try storagePlugin.storageService(for: .fromOutputs(name: "anotherBucket"))
            XCTFail("Expected StorageError.validation to be thrown")
        } catch {
            guard let storageError = error as? StorageError,
                  case .validation(let field, _, _, _) = storageError else {
                XCTFail("Expected StorageError.validation, got \(error)")
                return
            }
            XCTAssertEqual(field, "bucket")
        }
    }

    /// Given: A AWSS3StoragePlugin configured with additional bucket names
    /// When: storageService(for:) is invoked with .fromOutputs with a non-existing value
    /// Then: A StorageError.validation error is thrown
    func testStorageService_withInvalidBucketFromOutputs_shouldThrowValidationException() {
        storagePlugin.additionalBucketsByName = [
            additionalS3Bucket.name: additionalS3Bucket
        ]
        do {
            _ = try storagePlugin.storageService(for: .fromOutputs(name: "invalidBucket"))
            XCTFail("Expected StorageError.validation to be thrown")
        } catch {
            guard let storageError = error as? StorageError,
                  case .validation(let field, _, _, _) = storageError else {
                XCTFail("Expected StorageError.validation, got \(error)")
                return
            }
            XCTAssertEqual(field, "bucket")
        }
    }

    /// Given: A configured AWSS3StoragePlugin
    /// When: storageService(for:) is invoked with .fromBucketInfo
    /// Then: A valid AWSS3StorageService should be returned pointing to that bucket
    func testStorageService_withBucketFromBucketInfo_shouldReturnStorageService() throws {
        let storageService = try storagePlugin.storageService(for: .fromBucketInfo(additionalBucketInfo))
        guard let newService = storageService as? AWSS3StorageService else {
            XCTFail("Expected a AWSS3StorageService, got \(type(of: storageService))")
            return
        }
        XCTAssertFalse(newService === defaultService)
        XCTAssertEqual(newService.bucket, additionalBucketInfo.bucketName)
    }

    /// Given: A configured AWSS3StoragePlugin
    /// When: storageService(for:) is invoked with an invalid instance that conforms to StorageBucket
    /// Then: A StorageError.validation error is thrown
    func testStorageService_withInvalidStorageBucket_shouldThrowValidationException() {
        do {
            _ = try storagePlugin.storageService(for: InvalidBucket())
            XCTFail("Expected StorageError.validation to be thrown")
        } catch {
            guard let storageError = error as? StorageError,
                  case .validation(let field, _, _, _) = storageError else {
                XCTFail("Expected StorageError.validation, got \(error)")
                return
            }
            XCTAssertEqual(field, "bucket")
        }
    }

    /// Given: A configured AWSS3StoragePlugin
    /// When: storageService(for:) is invoked for a bucket that was not accessed before (i.e. a new one)
    /// Then: A new Storage Service should be created
    func testStorageService_withNewBucket_shouldReturnNewService() throws {
        XCTAssertEqual(storagePlugin.storageServicesByBucket.count, 1)
        _ = try storagePlugin.storageService(for: .fromBucketInfo(additionalBucketInfo))
        XCTAssertEqual(storagePlugin.storageServicesByBucket.count, 2)
    }

    /// Regression test for #4426: concurrent first uses of a bucket each created a storage service, and all but the one
    /// stored last were released while their uploads were still running.
    ///
    /// - Given: A configured AWSS3StoragePlugin
    /// - When:
    ///    - storageService(for:) is invoked concurrently for each of several buckets that were not accessed before
    /// - Then:
    ///    - every call for a bucket returns the one service stored for that bucket
    ///
    func testStorageService_withNewBucketConcurrently_shouldCreateOneService() throws {
        // MockAWSAuthService records calls without a lock, so concurrent service creation would corrupt it.
        storagePlugin.authService = AWSAuthService()
        // Start the transfer database's one-time recovery on a kept service, so a released duplicate can't trap in it.
        _ = try storagePlugin.storageService(for: .fromBucketInfo(.init(bucketName: "warmUpBucket", region: "us-east-1")))
        // Several buckets, so a reverted fix fails even where few threads overlap.
        for index in 1 ... 4 {
            let bucketInfo = BucketInfo(bucketName: "concurrentBucket\(index)", region: "us-east-2")
            let services = AtomicValue<[AWSS3StorageService]>(initialValue: [])
            DispatchQueue.concurrentPerform(iterations: 8) { _ in
                if let service = try? storagePlugin.storageService(for: .fromBucketInfo(bucketInfo)) as? AWSS3StorageService {
                    services.append(service)
                }
            }

            let returned = services.get()
            XCTAssertEqual(returned.count, 8, bucketInfo.bucketName)
            let stored = try XCTUnwrap(storagePlugin.storageServicesByBucket[bucketInfo.bucketName] as? AWSS3StorageService)
            let distinct = Set(returned.map { ObjectIdentifier($0) })
            XCTAssertEqual(distinct, [ObjectIdentifier(stored)], "\(bucketInfo.bucketName): \(distinct.count) services returned")
        }
        XCTAssertEqual(storagePlugin.storageServicesByBucket.count, 6)
    }

    /// Given: A configured AWSS3StoragePlugin
    /// When: storageService(for:) is invoked for a bucket that was accessed before (e.g. the default one)
    /// Then: A new Storage Service should not be created
    func testStorageService_withPreviouslyAccessedBucket_shouldReturnExistingService() throws {
        XCTAssertEqual(storagePlugin.storageServicesByBucket.count, 1)
        _ = try storagePlugin.storageService(for: .fromBucketInfo(defaultBucketInfo))
        XCTAssertEqual(storagePlugin.storageServicesByBucket.count, 1)
    }

    private struct InvalidBucket: StorageBucket {}
}
