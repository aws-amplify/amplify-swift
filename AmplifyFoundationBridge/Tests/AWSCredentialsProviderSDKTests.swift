//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AwsCommonRuntimeKit
import Smithy
import SmithyIdentity
@testable import AmplifyFoundation
@testable import AmplifyFoundationBridge

class AWSCredentialsProviderSDKTests: XCTestCase {
    
    // MARK: - AWSCredentialsProvider + CRT CredentialsProviding Tests
    
    /// Given: An AWSCredentialsProvider that also conforms to CRT CredentialsProviding
    /// When: I call resolve()
    /// Then: It should return AWSCredentials by converting from CRT credentials
    func testCRTCredentialsProvidingResolve() async throws {
        let provider = MockCRTCredentialsProvider()
        let credentials = try await provider.resolve()
        
        XCTAssertEqual(credentials.accessKeyId, "crt-access-key")
        XCTAssertEqual(credentials.secretAccessKey, "crt-secret-key")
    }
    
    /// Given: An AWSCredentialsProvider that also conforms to CRT CredentialsProviding
    /// When: CRT getCredentials() throws an error
    /// Then: resolve() should propagate the error
    func testCRTCredentialsProvidingResolveThrowsError() async throws {
        let provider = MockCRTCredentialsProviderWithError()
        
        do {
            _ = try await provider.resolve()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }
    }
    
    // MARK: - AWSCredentialsProvider + Smithy AWSCredentialIdentityResolver Tests
    
    /// Given: An Smithy AWSCredentialIdentityResolver that also conforms to  AWSCredentialsProvider
    /// When: I call resolve()
    /// Then: It should return AWSCredentials by converting from Smithy credentials
    func testSmithyCredentialIdentityResolverResolve() async throws {
        let provider = MockSmithyCredentialsProvider()
        let credentials = try await provider.resolve()
        
        XCTAssertEqual(credentials.accessKeyId, "smithy-access-key")
        XCTAssertEqual(credentials.secretAccessKey, "smithy-secret-key")
    }
    
    /// Given: An Smithy AWSCredentialIdentityResolver that also conforms to  AWSCredentialsProvider
    /// When: getIdentity() throws an error
    /// Then: resolve() should propagate the error
    func testSmithyCredentialIdentityResolverResolveThrowsError() async throws {
        let provider = MockSmithyCredentialsProviderWithError()
        
        do {
            _ = try await provider.resolve()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }
    }
    
    // MARK: - CRT CredentialsProviding + AWSCredentialsProvider Tests
    
    /// Given: A Static AWSCredentialsProvider that also conforms to CRT CredentialsProviding
    /// When: I call getCredentials()
    /// Then: It should return CRT Credentials by converting from AWSCredentials
    func testStaticAWSCredentialsProviderGetCRTCredentials() async throws {
        let provider = MockStaticAWSCredentialsProviderWithCRT()
        let credentials = try await provider.getCredentials()
        
        XCTAssertEqual(credentials.getAccessKey(), "aws-access-key")
        XCTAssertEqual(credentials.getSecret(), "aws-secret-key")
    }
    
    /// Given: A Temporary AWSCredentialsProvider that also conforms to CRT CredentialsProviding
    /// When: I call getCredentials()
    /// Then: It should return CRT Credentials by converting from AWSCredentials
    func testTemporaryAWSCredentialsProviderGetCRTCredentials() async throws {
        let provider = MockTemporaryAWSCredentialsProviderWithCRT()
        let credentials = try await provider.getCredentials()
        
        XCTAssertEqual(credentials.getAccessKey(), "aws-access-key")
        XCTAssertEqual(credentials.getSecret(), "aws-secret-key")
        XCTAssertEqual(credentials.getSessionToken(), "aws-session-token")
        XCTAssertNotNil(credentials.getExpiration())
    }
    
    /// Given: A CRT CredentialsProviding that also conforms to AWSCredentialsProvider
    /// When: resolve() throws an error
    /// Then: getCredentials() should propagate the error
    func testAWSCredentialsProviderGetCRTCredentialsThrowsError() async throws {
        let provider = MockAWSCredentialsProviderWithCRTError()
        
        do {
            _ = try await provider.getCredentials()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }
    }
    
    // MARK: - Smithy AWSCredentialIdentityResolver + AWSCredentialsProvider Tests
    
    /// Given: A  Static AWSCredentialIdentityResolver that also conforms to Smithy AWSCredentialIdentityResolver
    /// When: I call getIdentity()
    /// Then: It should return Smithy AWSCredentialIdentity by converting from AWSCredentials
    func testStaticAWSCredentialsProviderGetSmithyIdentity() async throws {
        let provider = MockStaticAWSCredentialsProviderWithSmithy()
        let identity = try await provider.getIdentity()
        
        XCTAssertEqual(identity.accessKey, "aws-access-key")
        XCTAssertEqual(identity.secret, "aws-secret-key")
    }
    
    /// Given: A Temporary AWSCredentialsProvider that also conforms to Smithy AWSCredentialIdentityResolver
    /// When: I call getIdentity()
    /// Then: It should return Smithy AWSCredentialIdentity by converting from AWSCredentials
    func testTemporaryAWSCredentialsProviderGetSmithyIdentity() async throws {
        let provider = MockTemporaryAWSCredentialsProviderWithSmithy()
        let identity = try await provider.getIdentity()
        
        XCTAssertEqual(identity.accessKey, "aws-access-key")
        XCTAssertEqual(identity.secret, "aws-secret-key")
        XCTAssertEqual(identity.sessionToken, "aws-session-token")
        XCTAssertNotNil(identity.expiration)
    }
    
    /// Given: A Smithy AWSCredentialIdentityResolver that also conforms to AWSCredentialsProvider
    /// When: resolve() throws an error
    /// Then: getIdentity() should propagate the error
    func testAWSCredentialsProviderGetSmithyIdentityThrowsError() async throws {
        let provider = MockAWSCredentialsProviderWithSmithyError()
        
        do {
            _ = try await provider.getIdentity(identityProperties: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }
    }
}

// MARK: - Mock Types

enum MockCredentialsError: Error {
    case failedToResolve
}

// Mocks for AWSCredentialsProvider + AWSCredentialsProvider
final class MockCRTCredentialsProvider: AwsCommonRuntimeKit.CredentialsProviding, AWSCredentialsProvider {
    func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        return try AwsCommonRuntimeKit.Credentials(
            accessKey: "crt-access-key",
            secret: "crt-secret-key",
            sessionToken: nil,
            expiration: nil
        )
    }
}

final class MockCRTCredentialsProviderWithError: AwsCommonRuntimeKit.CredentialsProviding, AWSCredentialsProvider {
    func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        throw MockCredentialsError.failedToResolve
    }
}

// Mocks for Smithy AWSCredentialIdentityResolver + AWSCredentialsProvider
final class MockSmithyCredentialsProvider: AWSCredentialIdentityResolver, AWSCredentialsProvider  {
    func getIdentity(identityProperties: Smithy.Attributes? = nil) async throws -> AWSCredentialIdentity {
        return AWSCredentialIdentity(
            accessKey: "smithy-access-key",
            secret: "smithy-secret-key"
        )
    }
}

final class MockSmithyCredentialsProviderWithError: AWSCredentialIdentityResolver, AWSCredentialsProvider {
    func getIdentity(identityProperties: Smithy.Attributes? = nil) async throws -> AWSCredentialIdentity {
        throw MockCredentialsError.failedToResolve
    }
}

// Mocks for AWSCredentialsProvider + CRT CredentialsProviding
final class MockStaticAWSCredentialsProviderWithCRT: AWSCredentialsProvider, AwsCommonRuntimeKit.CredentialsProviding {
    func resolve() async throws -> AWSCredentials {
        return MockStaticCredentials(
            accessKeyId: "aws-access-key",
            secretAccessKey: "aws-secret-key"
        )
    }
}

final class MockTemporaryAWSCredentialsProviderWithCRT: AWSCredentialsProvider, AwsCommonRuntimeKit.CredentialsProviding  {
    func resolve() async throws -> AWSCredentials {
        return MockTemporaryCredentials(
            sessionToken: "aws-session-token",
            expiration: Date(),
            accessKeyId: "aws-access-key",
            secretAccessKey: "aws-secret-key",
        )
    }
}

final class MockAWSCredentialsProviderWithCRTError: AWSCredentialsProvider, AwsCommonRuntimeKit.CredentialsProviding  {
    func resolve() async throws -> AWSCredentials {
        throw MockCredentialsError.failedToResolve
    }
}

// Mocks for AWSCredentialsProvider + Smithy AWSCredentialIdentityResolver
final class MockStaticAWSCredentialsProviderWithSmithy: AWSCredentialIdentityResolver, AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials {
        return MockStaticCredentials(
            accessKeyId: "aws-access-key",
            secretAccessKey: "aws-secret-key",
        )
    }
}

final class MockTemporaryAWSCredentialsProviderWithSmithy: AWSCredentialIdentityResolver, AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials {
        return MockTemporaryCredentials(
            sessionToken: "aws-session-token",
            expiration: Date(),
            accessKeyId: "aws-access-key",
            secretAccessKey: "aws-secret-key",
        )
    }
}

final class MockAWSCredentialsProviderWithSmithyError: AWSCredentialIdentityResolver, AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials {
        throw MockCredentialsError.failedToResolve
    }
}

struct MockStaticCredentials: AWSCredentials {
    let accessKeyId: String
    let secretAccessKey: String
}

struct MockTemporaryCredentials: AWSTemporaryCredentials {
    let sessionToken: String
    let expiration: Date
    let accessKeyId: String
    let secretAccessKey: String
}
