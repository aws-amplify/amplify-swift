//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSPluginsTestCommon
@testable import AWSS3StoragePlugin

// MARK: - Property-Based Tests for AWSS3StorageGetURLTask
//
// These tests use randomized inputs to validate universal properties
// of the method-to-signing-operation mapping in AWSS3StorageGetURLTask.

class AWSS3StorageGetURLTaskPropertyTests: XCTestCase {

    // MARK: - Helpers

    /// Generates a random valid storage path string (no leading slash, non-empty, non-whitespace).
    private func randomValidPath() -> String {
        let segments = Int.random(in: 1...5)
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
        var parts: [String] = []
        for _ in 0..<segments {
            let length = Int.random(in: 1...12)
            let segment = String((0..<length).map { _ in characters.randomElement()! })
            parts.append(segment)
        }
        return parts.joined(separator: "/")
    }

    /// Returns a random StorageAccessMethod value.
    private func randomMethod() -> StorageAccessMethod {
        return Bool.random() ? .get : .put
    }

    // MARK: - Property 1: Method-to-signing-operation mapping
    //
    // **Validates: Requirements 1.2, 1.3, 1.4**
    //
    // For any valid storage path and for any StorageAccessMethod value,
    // AWSS3StorageGetURLTask shall invoke getPreSignedURL with
    // .putObject when method is .put, and .getObject when method
    // is .get (or when no method is specified).

    func testProperty1_MethodToSigningOperationMapping() async throws {
        let iterations = 100

        for i in 0..<iterations {
            let path = randomValidPath()
            let method = randomMethod()

            let serviceMock = MockAWSS3StorageService()
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

            var capturedSigningOperation: AWSS3SigningOperation?

            serviceMock.getPreSignedURLHandler = { _, signingOperation, _ in
                capturedSigningOperation = signingOperation
                return tempURL
            }

            let pluginOptions = AWSStorageGetURLOptions(method: method)
            let request = StorageGetURLRequest(
                path: StringStoragePath.fromString(path),
                options: .init(pluginOptions: pluginOptions)
            )
            let task = AWSS3StorageGetURLTask(request, storageBehaviour: serviceMock)

            _ = try await task.value

            guard let captured = capturedSigningOperation else {
                XCTFail("Iteration \(i): getPreSignedURL was not called for path=\(path), method=\(method)")
                continue
            }

            switch method {
            case .put:
                if case .putObject = captured {
                    // correct
                } else {
                    XCTFail("Iteration \(i): Expected .putObject for method .put, got \(captured) (path=\(path))")
                }
            case .get:
                if case .getObject = captured {
                    // correct
                } else {
                    XCTFail("Iteration \(i): Expected .getObject for method .get, got \(captured) (path=\(path))")
                }
            }
        }
    }

    /// Validates that when no method is specified (default), the signing operation is .getObject.
    /// **Validates: Requirements 1.2**
    func testProperty1_DefaultMethodMapsToGetObject() async throws {
        let iterations = 100

        for i in 0..<iterations {
            let path = randomValidPath()

            let serviceMock = MockAWSS3StorageService()
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

            var capturedSigningOperation: AWSS3SigningOperation?

            serviceMock.getPreSignedURLHandler = { _, signingOperation, _ in
                capturedSigningOperation = signingOperation
                return tempURL
            }

            // No pluginOptions — should default to .get → .getObject
            let request = StorageGetURLRequest(
                path: StringStoragePath.fromString(path),
                options: .init()
            )
            let task = AWSS3StorageGetURLTask(request, storageBehaviour: serviceMock)

            _ = try await task.value

            guard let captured = capturedSigningOperation else {
                XCTFail("Iteration \(i): getPreSignedURL was not called for path=\(path)")
                continue
            }

            if case .getObject = captured {
                // correct
            } else {
                XCTFail("Iteration \(i): Expected .getObject for default (no pluginOptions), got \(captured) (path=\(path))")
            }
        }
    }
}


// MARK: - Property 2: Expiration forwarding for PUT
//
// **Validates: Requirements 3.1**
//
// For any valid storage path and for any positive expiration value,
// when the method is .put, the AWSS3StorageGetURLTask shall pass
// the expiration value through to getPreSignedURL unchanged.

extension AWSS3StorageGetURLTaskPropertyTests {

    func testProperty2_ExpirationForwardingForPUT() async throws {
        let iterations = 100

        for i in 0..<iterations {
            let path = randomValidPath()
            let expires = Int.random(in: 1...86400)

            let serviceMock = MockAWSS3StorageService()
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

            var capturedExpires: Int?

            serviceMock.getPreSignedURLHandler = { _, _, expiresValue in
                capturedExpires = expiresValue
                return tempURL
            }

            let pluginOptions = AWSStorageGetURLOptions(method: .put)
            let request = StorageGetURLRequest(
                path: StringStoragePath.fromString(path),
                options: .init(expires: expires, pluginOptions: pluginOptions)
            )
            let task = AWSS3StorageGetURLTask(request, storageBehaviour: serviceMock)

            _ = try await task.value

            guard let captured = capturedExpires else {
                XCTFail("Iteration \(i): getPreSignedURL was not called for path=\(path), expires=\(expires)")
                continue
            }

            XCTAssertEqual(
                captured,
                expires,
                "Iteration \(i): Expected expires=\(expires) to be forwarded unchanged, got \(captured) (path=\(path))"
            )
        }
    }
}


// MARK: - Property 3: Object existence validation conditional on method
//
// **Validates: Requirements 5.1, 5.2**
//
// For any valid storage path and for any StorageAccessMethod value, when
// validateObjectExistence is true, the AWSS3StorageGetURLTask shall
// call validateObjectExistence if and only if the method is .get.
// When the method is .put, the existence check shall be skipped
// regardless of the validateObjectExistence setting.

extension AWSS3StorageGetURLTaskPropertyTests {

    func testProperty3_ObjectExistenceValidationConditionalOnMethod() async throws {
        let iterations = 100

        for i in 0..<iterations {
            let path = randomValidPath()
            let method = randomMethod()

            let serviceMock = MockAWSS3StorageService()
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

            var validateObjectExistenceCalled = false

            serviceMock.validateObjectExistenceHandler = { _ in
                validateObjectExistenceCalled = true
            }

            serviceMock.getPreSignedURLHandler = { _, _, _ in
                return tempURL
            }

            let pluginOptions = AWSStorageGetURLOptions(
                validateObjectExistence: true,
                method: method
            )
            let request = StorageGetURLRequest(
                path: StringStoragePath.fromString(path),
                options: .init(pluginOptions: pluginOptions)
            )
            let task = AWSS3StorageGetURLTask(request, storageBehaviour: serviceMock)

            _ = try await task.value

            switch method {
            case .get:
                XCTAssertTrue(
                    validateObjectExistenceCalled,
                    "Iteration \(i): Expected validateObjectExistence to be called for method=.get (path=\(path))"
                )
                let hasValidateInteraction = serviceMock.interactions.contains { $0.hasPrefix("validateObjectExistence") }
                XCTAssertTrue(
                    hasValidateInteraction,
                    "Iteration \(i): Expected validateObjectExistence in interactions for method=.get (path=\(path))"
                )
            case .put:
                XCTAssertFalse(
                    validateObjectExistenceCalled,
                    "Iteration \(i): Expected validateObjectExistence NOT to be called for method=.put (path=\(path))"
                )
                let hasValidateInteraction = serviceMock.interactions.contains { $0.hasPrefix("validateObjectExistence") }
                XCTAssertFalse(
                    hasValidateInteraction,
                    "Iteration \(i): Expected no validateObjectExistence in interactions for method=.put (path=\(path))"
                )
            }
        }
    }
}



// MARK: - Property 4: Accelerate forwarding for PUT
//
// **Validates: Requirements 6.3**
//
// For any valid storage path with transfer acceleration enabled
// and method set to .put, the AWSS3StorageGetURLTask shall pass
// the accelerate flag through to getPreSignedURL.

extension AWSS3StorageGetURLTaskPropertyTests {

    func testProperty4_AccelerateForwardingForPUT() async throws {
        let iterations = 100

        for i in 0..<iterations {
            let path = randomValidPath()
            let accelerateEnabled = true

            let serviceMock = MockAWSS3StorageService()
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

            var capturedAccelerate: Bool?
            var accelerateWasCaptured = false

            serviceMock.getPreSignedURLWithAccelerateHandler = { _, _, _, accelerate, _ in
                capturedAccelerate = accelerate
                accelerateWasCaptured = true
                return tempURL
            }

            let pluginOptions: [String: Any] = [
                "useAccelerateEndpoint": accelerateEnabled
            ]
            let request = StorageGetURLRequest(
                path: StringStoragePath.fromString(path),
                options: .init(pluginOptions: pluginOptions)
            )
            let task = AWSS3StorageGetURLTask(request, storageBehaviour: serviceMock)

            _ = try await task.value

            guard accelerateWasCaptured else {
                XCTFail("Iteration \(i): getPreSignedURL was not called for path=\(path)")
                continue
            }

            XCTAssertEqual(
                capturedAccelerate,
                accelerateEnabled,
                "Iteration \(i): Expected accelerate=\(accelerateEnabled) to be forwarded, got \(String(describing: capturedAccelerate)) (path=\(path))"
            )
        }
    }

    /// Validates that accelerate=false is also forwarded correctly.
    func testProperty4_AccelerateDisabledForwarding() async throws {
        let iterations = 100

        for i in 0..<iterations {
            let path = randomValidPath()
            let accelerateEnabled = Bool.random()

            let serviceMock = MockAWSS3StorageService()
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

            var capturedAccelerate: Bool?
            var accelerateWasCaptured = false

            serviceMock.getPreSignedURLWithAccelerateHandler = { _, _, _, accelerate, _ in
                capturedAccelerate = accelerate
                accelerateWasCaptured = true
                return tempURL
            }

            let pluginOptions: [String: Any] = [
                "useAccelerateEndpoint": accelerateEnabled
            ]
            let request = StorageGetURLRequest(
                path: StringStoragePath.fromString(path),
                options: .init(pluginOptions: pluginOptions)
            )
            let task = AWSS3StorageGetURLTask(request, storageBehaviour: serviceMock)

            _ = try await task.value

            guard accelerateWasCaptured else {
                XCTFail("Iteration \(i): getPreSignedURL was not called for path=\(path)")
                continue
            }

            XCTAssertEqual(
                capturedAccelerate,
                accelerateEnabled,
                "Iteration \(i): Expected accelerate=\(accelerateEnabled) to be forwarded, got \(String(describing: capturedAccelerate)) (path=\(path))"
            )
        }
    }
}
