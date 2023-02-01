//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSS3StoragePlugin
@testable import AWSPluginsTestCommon
@testable import AmplifyTestCommon
import XCTest

// swiftlint:disable:next type_name
class AWSS3StorageServiceGetPreSignedURLBehaviorTests: XCTestCase {
    
    var systemUnderTest: AWSS3StorageService!
    var authService: MockAWSAuthService!
    var database: MockStorageTransferDatabase!
    var builder: MockAWSS3PreSignedURLBuilder!
    var region: String!
    var bucket: String!
    var serviceKey: String!
    var presignedURL: URL!
    var expires: Int!
    
    override func setUpWithError() throws {
        authService = MockAWSAuthService()
        database = MockStorageTransferDatabase()
        builder = MockAWSS3PreSignedURLBuilder()
        region = UUID().uuidString
        bucket = UUID().uuidString
        serviceKey = UUID().uuidString
        presignedURL = URL(fileURLWithPath: NSTemporaryDirectory().appendingPathComponent(serviceKey))
        expires = Int(Date.distantFuture.timeIntervalSince1970)
        systemUnderTest = try AWSS3StorageService(authService: authService,
                                                  region: region,
                                                  bucket: bucket,
                                                  storageTransferDatabase: database)
        systemUnderTest.preSignedURLBuilder = builder
        
        let url = try XCTUnwrap(presignedURL)
        builder.getPreSignedURLHandler = { (_,_,_) in
            return url
        }
    }
    
    override func tearDownWithError() throws {
        authService = nil
        builder = nil
        region = nil
        bucket = nil
        serviceKey = nil
        presignedURL = nil
        expires = nil
        systemUnderTest = nil
    }
    
    /// - Given: A storage service configured to use a AWSS3PreSignedURLBuilder
    /// - When: A presigned URL is requested for a **AWSS3SigningOperation.getObject** operation
    /// - Then: A valid URL is returned
    func testForGetObject() async throws {
        let url = try await systemUnderTest.getPreSignedURL(serviceKey: serviceKey,
                                                            signingOperation: .getObject,
                                                            expires: expires)
        XCTAssertEqual(url, presignedURL)
        XCTAssertEqual(builder.interactions, [
            "getPreSignedURL(key:signingOperation:expires:) \(serviceKey ?? "") \(AWSS3SigningOperation.getObject) \(String(describing: expires))"
        ])
    }
    
    /// - Given: A storage service configured to use a AWSS3PreSignedURLBuilder
    /// - When: A presigned URL is requested for a **AWSS3SigningOperation.putObject** operation
    /// - Then: A valid URL is returned
    func testForPutObject() async throws {
        let url = try await systemUnderTest.getPreSignedURL(serviceKey: serviceKey,
                                                            signingOperation: .putObject,
                                                            expires: expires)
        XCTAssertEqual(url, presignedURL)
        XCTAssertEqual(builder.interactions, [
            "getPreSignedURL(key:signingOperation:expires:) \(serviceKey ?? "") \(AWSS3SigningOperation.putObject) \(String(describing: expires))"
        ])
    }
    
    /// - Given: A storage service configured to use a AWSS3PreSignedURLBuilder
    /// - When: A presigned URL is requested for a **AWSS3SigningOperation.uploadPart** operation
    /// - Then: A valid URL is returned
    func testForUploadPart() async throws {
        let operation = AWSS3SigningOperation.uploadPart(partNumber: 0, uploadId: UUID().uuidString)
        let url = try await systemUnderTest.getPreSignedURL(serviceKey: serviceKey,
                                                            signingOperation: operation,
                                                            expires: expires)
        XCTAssertEqual(url, presignedURL)
        XCTAssertEqual(builder.interactions, [
            "getPreSignedURL(key:signingOperation:expires:) \(serviceKey ?? "") \(operation) \(String(describing: expires))"
        ])
    }
}
