//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSS3
import Amplify
import ClientRuntime
import XCTest

@testable import AWSPluginsTestCommon
@testable import AWSS3StoragePlugin

final class AWSS3StorageServiceListTests: XCTestCase {
    
    var systemUnderTest: AWSS3StorageService!
    var authService: MockAWSAuthService!
    var client: MockS3Client!
    var region: String!
    var bucket: String!
    var prefix: String!
    var path: String!
    var targetIdentityId: String!
    
    override func setUp() async throws {
        authService = MockAWSAuthService()
        client = MockS3Client()
        region = UUID().uuidString
        bucket = UUID().uuidString
        prefix = UUID().uuidString
        path = UUID().uuidString
        targetIdentityId = UUID().uuidString
        systemUnderTest = try AWSS3StorageService(authService: authService,
                                              region: region,
                                              bucket: bucket)
        systemUnderTest.client = client
    }
    
    override func tearDown() async throws {
        authService = nil
        client = nil
        region = nil
        bucket = nil
        prefix = nil
        path = nil
        targetIdentityId = nil
        systemUnderTest = nil
    }
    
    /// Given: A empty S3 bucket (client)
    /// When: A listing of it is requested using typical parameters
    /// Then: The service returns an empty list of StorageListResult.Item
    func testEmptyListing() async throws {
        client.listObjectsV2Handler = { _ in
            return .init(contents: [])
        }
        let options = StorageListRequest.Options(accessLevel: .protected, targetIdentityId: targetIdentityId, path: path)
        let listing = try await systemUnderTest.list(prefix: prefix, options: options)
        XCTAssertEqual(listing.items.map { $0.key }, [])
    }
    
    /// Given: A empty S3 bucket (client)
    /// When: A listing of it is requested using an `nil` path
    /// Then: The service returns an empty list of StorageListResult.Item
    func testEmptyListingForNilPath() async throws {
        client.listObjectsV2Handler = { _ in
            return .init(contents: [])
        }
        let options = StorageListRequest.Options(accessLevel: .protected, targetIdentityId: targetIdentityId, path: nil)
        let listing = try await systemUnderTest.list(prefix: prefix, options: options)
        XCTAssertEqual(listing.items.map { $0.key }, [])
    }

    /// Given: A misconfigured or S3 bucket with restricted permissions
    /// When: A listing of it is requested using typical parameters
    /// Then: The service throws a `StorageError` error
    func testSdkError() async throws {
        client.listObjectsV2Handler = { _ in
            let response = HttpResponse(body: .empty, statusCode: .forbidden)
            throw try SdkError<ListObjectsV2OutputError>.service(ListObjectsV2OutputError(httpResponse: response), response)
        }
        let options = StorageListRequest.Options(accessLevel: .protected, targetIdentityId: targetIdentityId, path: path)
        do {
            let _ = try await systemUnderTest.list(prefix: prefix, options: options)
        } catch let error as StorageError {
            XCTAssertNotNil(error)
        }
    }

    /// Given: An unexpected bug in the AWS SDK that throws an internal client-side error
    /// When: A listing of it is requested using typical parameters
    /// Then: The service throws a `StorageError` error
    func testUnexpectedError() async throws {
        enum TestError: Error {
            case unexpected
        }
        client.listObjectsV2Handler = { _ in
            throw TestError.unexpected
        }
        let options = StorageListRequest.Options(accessLevel: .protected, targetIdentityId: targetIdentityId, path: path)
        do {
            let _ = try await systemUnderTest.list(prefix: prefix, options: options)
        } catch let error as StorageError {
            XCTAssertNotNil(error)
        }
    }
    
    /// Given: A session holding an empty string targetIdentityId
    /// When: A listing of it is requested using this empty targetIdentityId
    /// Then: The service throws a `StorageError.validation` error
    func testValidateEmptyTargetIdentityIdError() async throws {
        let options = StorageListRequest.Options(accessLevel: .protected,
                                                 targetIdentityId: "",
                                                 path: path)
        do {
            let _ = try await systemUnderTest.list(prefix: prefix, options: options)
            XCTFail("Missing StorageError")
        } catch StorageError.validation(let field, let description, let recovery, _) {
            XCTAssertEqual(field, StorageErrorConstants.identityIdIsEmpty.field)
            XCTAssertEqual(description, StorageErrorConstants.identityIdIsEmpty.errorDescription)
            XCTAssertEqual(recovery, StorageErrorConstants.identityIdIsEmpty.recoverySuggestion)
        }
    }

    /// Given: A typical session
    /// When: A listing of it is requested using `accessLevel: .private`
    /// Then: The service throws a `StorageError.validation` error
    func testValidateTargetIdentityIdWithPrivateAccessLevelError() async throws {
        let options = StorageListRequest.Options(accessLevel: .private,
                                                 targetIdentityId: targetIdentityId,
                                                 path: path)
        do {
            let _ = try await systemUnderTest.list(prefix: prefix, options: options)
            XCTFail("Missing StorageError")
        } catch StorageError.validation(let field, let description, let recovery, _) {
            XCTAssertEqual(field, StorageErrorConstants.invalidAccessLevelWithTarget.field)
            XCTAssertEqual(description, StorageErrorConstants.invalidAccessLevelWithTarget.errorDescription)
            XCTAssertEqual(recovery, StorageErrorConstants.invalidAccessLevelWithTarget.recoverySuggestion)
        }
    }

    /// Given: A typical session
    /// When: A listing of it is requested using an empty string value for the `path` parameter
    /// Then: The service throws a `StorageError.validation` error
    func testValidateEmptyPathError() async throws {
        let options = StorageListRequest.Options(accessLevel: .protected,
                                                 targetIdentityId: targetIdentityId,
                                                 path: "")
        do {
            let _ = try await systemUnderTest.list(prefix: prefix, options: options)
            XCTFail("Missing StorageError")
        } catch StorageError.validation(let field, let description, let recovery, _) {
            XCTAssertEqual(field, StorageErrorConstants.pathIsEmpty.field)
            XCTAssertEqual(description, StorageErrorConstants.pathIsEmpty.errorDescription)
            XCTAssertEqual(recovery, StorageErrorConstants.pathIsEmpty.recoverySuggestion)
        }
    }
}
