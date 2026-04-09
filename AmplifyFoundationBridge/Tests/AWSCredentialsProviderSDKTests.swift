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

    // MARK: - Adapter Tests

    /// Given: A Foundation AWSCredentialsProvider
    /// When: I wrap it with FoundationToSDKCredentialsAdapter
    /// Then: It should work as both AWSCredentialsProvider and AWSCredentialIdentityResolver
    func testFoundationToSDKCredentialsAdapter() async throws {
        let foundationProvider = MockFoundationProvider()
        let adapter = FoundationToSDKCredentialsAdapter(provider: foundationProvider)

        // Test as AWSCredentialsProvider
        let awsCredentials = try await adapter.resolve()
        XCTAssertEqual(awsCredentials.accessKeyId, "foundation-access-key")
        XCTAssertEqual(awsCredentials.secretAccessKey, "foundation-secret-key")

        // Test as AWSCredentialIdentityResolver
        let identity = try await adapter.getIdentity()
        XCTAssertEqual(identity.accessKey, "foundation-access-key")
        XCTAssertEqual(identity.secret, "foundation-secret-key")
    }

    /// Given: A Foundation AWSCredentialsProvider that throws an error
    /// When: I wrap it with FoundationToSDKCredentialsAdapter
    /// Then: Both interfaces should propagate the error
    func testFoundationToSDKCredentialsAdapterWithError() async throws {
        let foundationProvider = MockFoundationProviderWithError()
        let adapter = FoundationToSDKCredentialsAdapter(provider: foundationProvider)

        // Test resolve() propagates error
        do {
            _ = try await adapter.resolve()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }

        // Test getIdentity() propagates error
        do {
            _ = try await adapter.getIdentity()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }
    }

    /// Given: An SDK AWSCredentialIdentityResolver
    /// When: I wrap it with SDKToFoundationCredentialsAdapter
    /// Then: It should work as AWSCredentialsProvider
    func testSDKToFoundationCredentialsAdapter() async throws {
        let sdkResolver = MockSDKResolver()
        let adapter = SDKToFoundationCredentialsAdapter(resolver: sdkResolver)

        let identity = try await adapter.getIdentity()
        XCTAssertEqual(identity.accessKey, "sdk-access-key")
        XCTAssertEqual(identity.secret, "sdk-secret-key")

        let awsCredentials = try await adapter.resolve()
        XCTAssertEqual(awsCredentials.accessKeyId, "sdk-access-key")
        XCTAssertEqual(awsCredentials.secretAccessKey, "sdk-secret-key")
    }

    /// Given: An SDK AWSCredentialIdentityResolver with temporary credentials
    /// When: I wrap it with SDKToFoundationCredentialsAdapter
    /// Then: It should return temporary AWSCredentials with session token
    func testSDKToFoundationCredentialsAdapterWithTemporaryCredentials() async throws {
        let sdkResolver = MockSDKResolverWithTemporaryCredentials()
        let adapter = SDKToFoundationCredentialsAdapter(resolver: sdkResolver)

        let identity = try await adapter.getIdentity()
        XCTAssertEqual(identity.accessKey, "sdk-temp-access-key")
        XCTAssertEqual(identity.secret, "sdk-temp-secret-key")
        XCTAssertNotNil(identity.sessionToken)
        XCTAssertEqual(identity.sessionToken!, "sdk-session-token")
        XCTAssertNotNil(identity.expiration)

        let credentials = try await adapter.resolve()
        XCTAssertEqual(credentials.accessKeyId, "sdk-temp-access-key")
        XCTAssertEqual(credentials.secretAccessKey, "sdk-temp-secret-key")

        if let tempCredentials = credentials as? AWSTemporaryCredentials {
            XCTAssertEqual(tempCredentials.sessionToken, "sdk-session-token")
            XCTAssertNotNil(tempCredentials.expiration)
        } else {
            XCTFail("Expected temporary credentials")
        }
    }

    /// Given: An SDK AWSCredentialIdentityResolver that throws an error
    /// When: I wrap it with SDKToFoundationCredentialsAdapter
    /// Then: It should propagate the error
    func testSDKToFoundationCredentialsAdapterWithError() async throws {
        let sdkResolver = MockSDKResolverWithError()
        let adapter = SDKToFoundationCredentialsAdapter(resolver: sdkResolver)

        // Test getIdentity() propagates error
        do {
            _ = try await adapter.getIdentity()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }

        // Test resolve() propagates error
        do {
            _ = try await adapter.resolve()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }
    }

    /// Given: A CRT CredentialsProviding
    /// When: I wrap it with CRTToFoundationCredentialsAdapter
    /// Then: It should work as AWSCredentialsProvider
    func testCRTToFoundationCredentialsAdapter() async throws {
        let crtProvider = MockCRTProvider()
        let adapter = CRTToFoundationCredentialsAdapter(provider: crtProvider)

        let crtCredentials = try await adapter.getCredentials()
        XCTAssertNotNil(crtCredentials.getAccessKey())
        XCTAssertNotNil(crtCredentials.getSecret())
        XCTAssertEqual(crtCredentials.getAccessKey(), "crt-access-key")
        XCTAssertEqual(crtCredentials.getSecret(), "crt-secret-key")

        let credentials = try await adapter.resolve()
        XCTAssertEqual(credentials.accessKeyId, "crt-access-key")
        XCTAssertEqual(credentials.secretAccessKey, "crt-secret-key")
    }

    /// Given: A CRT CredentialsProviding with temporary credentials
    /// When: I wrap it with CRTToFoundationCredentialsAdapter
    /// Then: It should return temporary AWSCredentials with session token
    func testCRTToFoundationCredentialsAdapterWithTemporaryCredentials() async throws {
        let crtProvider = MockCRTProviderWithTemporaryCredentials()
        let adapter = CRTToFoundationCredentialsAdapter(provider: crtProvider)

        let crtCredentials = try await adapter.getCredentials()
        XCTAssertNotNil(crtCredentials.getAccessKey())
        XCTAssertNotNil(crtCredentials.getSecret())
        XCTAssertNotNil(crtCredentials.getSessionToken())
        XCTAssertNotNil(crtCredentials.getExpiration())
        XCTAssertEqual(crtCredentials.getAccessKey(), "crt-temp-access-key")
        XCTAssertEqual(crtCredentials.getSecret(), "crt-temp-secret-key")
        XCTAssertEqual(crtCredentials.getSessionToken(), "crt-session-token")

        let credentials = try await adapter.resolve()
        XCTAssertEqual(credentials.accessKeyId, "crt-temp-access-key")
        XCTAssertEqual(credentials.secretAccessKey, "crt-temp-secret-key")

        if let tempCredentials = credentials as? AWSTemporaryCredentials {
            XCTAssertEqual(tempCredentials.sessionToken, "crt-session-token")
            XCTAssertNotNil(tempCredentials.expiration)
        } else {
            XCTFail("Expected temporary credentials")
        }
    }

    /// Given: A CRT CredentialsProviding that throws an error
    /// When: I wrap it with CRTToFoundationCredentialsAdapter
    /// Then: It should propagate the error
    func testCRTToFoundationCredentialsAdapterWithError() async throws {
        let crtProvider = MockCRTProviderWithError()
        let adapter = CRTToFoundationCredentialsAdapter(provider: crtProvider)

        // Test getCredentials() propagates error
        do {
            _ = try await adapter.getCredentials()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }

        // Test resolve() propagates error
        do {
            _ = try await adapter.resolve()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }
    }

    /// Given: A Foundation AWSCredentialsProvider
    /// When: I wrap it with FoundationToCRTCredentialsAdapter
    /// Then: It should work as CRT CredentialsProviding
    func testFoundationToCRTCredentialsAdapter() async throws {
        let foundationProvider = MockFoundationProvider()
        let adapter = FoundationToCRTCredentialsAdapter(provider: foundationProvider)

        let awsCredentials = try await adapter.resolve()
        XCTAssertEqual(awsCredentials.accessKeyId, "foundation-access-key")
        XCTAssertEqual(awsCredentials.secretAccessKey, "foundation-secret-key")

        let credentials = try await adapter.getCredentials()
        XCTAssertEqual(credentials.getAccessKey(), "foundation-access-key")
        XCTAssertEqual(credentials.getSecret(), "foundation-secret-key")
    }

    /// Given: A Foundation AWSCredentialsProvider with temporary credentials
    /// When: I wrap it with FoundationToCRTCredentialsAdapter
    /// Then: It should return CRT credentials with session token
    func testFoundationToCRTCredentialsAdapterWithTemporaryCredentials() async throws {
        let foundationProvider = MockFoundationProviderWithTemporaryCredentials()
        let adapter = FoundationToCRTCredentialsAdapter(provider: foundationProvider)

        let awsCredentials = try await adapter.resolve()
        XCTAssertEqual(awsCredentials.accessKeyId, "foundation-temp-access-key")
        XCTAssertEqual(awsCredentials.secretAccessKey, "foundation-temp-secret-key")
        if let tempCredentials = awsCredentials as? AWSTemporaryCredentials {
            XCTAssertEqual(tempCredentials.sessionToken, "foundation-session-token")
            XCTAssertNotNil(tempCredentials.expiration)
        } else {
            XCTFail("Expected temporary credentials")
        }

        let credentials = try await adapter.getCredentials()
        XCTAssertEqual(credentials.getAccessKey(), "foundation-temp-access-key")
        XCTAssertEqual(credentials.getSecret(), "foundation-temp-secret-key")
        XCTAssertEqual(credentials.getSessionToken(), "foundation-session-token")
        XCTAssertNotNil(credentials.getExpiration())
    }

    /// Given: A Foundation AWSCredentialsProvider that throws an error
    /// When: I wrap it with FoundationToCRTCredentialsAdapter
    /// Then: It should propagate the error
    func testFoundationToCRTCredentialsAdapterWithError() async throws {
        let foundationProvider = MockFoundationProviderWithError()
        let adapter = FoundationToCRTCredentialsAdapter(provider: foundationProvider)

        // Test resolve() propagates error
        do {
            _ = try await adapter.resolve()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockCredentialsError)
        }

        // Test getCredentials() propagates error
        do {
            _ = try await adapter.getCredentials()
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

// MARK: - Mock Types for Adapter Tests

final class MockFoundationProvider: AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials {
        return MockStaticCredentials(
            accessKeyId: "foundation-access-key",
            secretAccessKey: "foundation-secret-key"
        )
    }
}

final class MockFoundationProviderWithTemporaryCredentials: AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials {
        return MockCredentials(
            sessionToken: "foundation-session-token",
            accessKeyId: "foundation-temp-access-key",
            secretAccessKey: "foundation-temp-secret-key",
            expiration: Date().addingTimeInterval(3_600)
        )
    }
}

final class MockFoundationProviderWithError: AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials {
        throw MockCredentialsError.failedToResolve
    }
}

final class MockSDKResolver: AWSCredentialIdentityResolver {
    func getIdentity(identityProperties: Smithy.Attributes?) async throws -> AWSCredentialIdentity {
        return AWSCredentialIdentity(
            accessKey: "sdk-access-key",
            secret: "sdk-secret-key"
        )
    }
}

final class MockSDKResolverWithTemporaryCredentials: AWSCredentialIdentityResolver {
    func getIdentity(identityProperties: Smithy.Attributes?) async throws -> AWSCredentialIdentity {
        return AWSCredentialIdentity(
            accessKey: "sdk-temp-access-key",
            secret: "sdk-temp-secret-key",
            expiration: Date().addingTimeInterval(3_600),
            sessionToken: "sdk-session-token"
        )
    }
}

final class MockSDKResolverWithError: AWSCredentialIdentityResolver {
    func getIdentity(identityProperties: Smithy.Attributes?) async throws -> AWSCredentialIdentity {
        throw MockCredentialsError.failedToResolve
    }
}

final class MockCRTProvider: AwsCommonRuntimeKit.CredentialsProviding {
    func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        return try AwsCommonRuntimeKit.Credentials(
            accessKey: "crt-access-key",
            secret: "crt-secret-key",
            sessionToken: nil,
            expiration: nil
        )
    }
}

final class MockCRTProviderWithTemporaryCredentials: AwsCommonRuntimeKit.CredentialsProviding {
    func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        return try AwsCommonRuntimeKit.Credentials(
            accessKey: "crt-temp-access-key",
            secret: "crt-temp-secret-key",
            sessionToken: "crt-session-token",
            expiration: Date().addingTimeInterval(3_600)
        )
    }
}

final class MockCRTProviderWithError: AwsCommonRuntimeKit.CredentialsProviding {
    func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        throw MockCredentialsError.failedToResolve
    }
}
