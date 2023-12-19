//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
@testable import AWSPluginsTestCommon
import XCTest

class VerifyDevicePasswordSRPSignatureTests: XCTestCase {
    private var srpClient: MockSRPClientBehavior!
    
    override func setUp() async throws {
        MockSRPClientBehavior.reset()
        srpClient = MockSRPClientBehavior()
    }
    
    override func tearDown() {
        MockSRPClientBehavior.reset()
        srpClient = nil
    }

    /// Given: A VerifyDevicePasswordSRP
    /// When: signature is invoked
    /// Then: a non-empty string is returned
    func testSignature_withValidValues_shouldReturnSignature() async {
        do {
            let signature = try signature()
            XCTAssertFalse(signature.isEmpty)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    /// Given: A VerifyDevicePasswordSRP
    /// When: signature is invoked and the srpClient throws an SRPError error when generating a shared secret
    /// Then: a .calculation error is thrown
    func testSignature_withSRPErrorOnSharedSecret_shouldThrowCalculationError() async {
        srpClient.sharedSecret = .failure(SRPError.numberConversion)
        do {
            try signature()
            XCTFail("Should not succeed")
        } catch {
            guard case .calculation(let srpError) = error as? SignInError else {
                XCTFail("Expected SRPError.calculation, got \(error)")
                return
            }

            XCTAssertEqual(srpError, .numberConversion)
        }
    }
    
    /// Given: A VerifyDevicePasswordSRP
    /// When: signature is invoked and the srpClient throws a non-SRPError error when generating a shared secret
    /// Then: a .configuration error is thrown
    func testSignature_withOtherErrorOnSharedSecret_shouldThrowCalculationError() async {
        srpClient.sharedSecret = .failure(CancellationError())
        do {
            try signature()
            XCTFail("Should not succeed")
        } catch {
            guard case .configuration(let message) = error as? SignInError else {
                XCTFail("Expected SRPError.configuration, got \(error)")
                return
            }

            XCTAssertEqual(message, "Could not calculate shared secret")
        }
    }
    
    /// Given: A VerifyDevicePasswordSRP
    /// When: signature is invoked and the srpClient throws a SRPError error when generating an authentication key
    /// Then: a .calculation error is thrown
    func testSignature_withSRPErrorOnAuthenticationKey_shouldThrowCalculationError() async {
        MockSRPClientBehavior.authenticationKey = .failure(SRPError.numberConversion)
        do {
            try signature()
            XCTFail("Should not succeed")
        } catch {
            guard case .calculation(let srpError) = error as? SignInError else {
                XCTFail("Expected SRPError.calculation, got \(error)")
                return
            }

            XCTAssertEqual(srpError, .numberConversion)
        }
    }
    
    /// Given: A VerifyDevicePasswordSRP
    /// When: signature is invoked and the srpClient throws a non-SRPError error when generating an authentication key
    /// Then: a .configuration error is thrown
    func testSignature_withOtherErrorOnAuthenticationKey_shouldThrowCalculationError() async {
        MockSRPClientBehavior.authenticationKey = .failure(CancellationError())
        do {
            try signature()
            XCTFail("Should not succeed")
        } catch {
            guard case .configuration(let message) = error as? SignInError else {
                XCTFail("Expected SRPError.configuration, got \(error)")
                return
            }

            XCTAssertEqual(message, "Could not calculate signature")
        }
    }
    
    @discardableResult
    private func signature() throws -> String {
        let action = VerifyDevicePasswordSRP(
            stateData: .testData,
            authResponse: InitiateAuthOutput.validTestData
        )

        return try action.signature(
            deviceGroupKey: "deviceGroupKey",
            deviceKey: "deviceKey",
            deviceSecret: "deviceSecret",
            saltHex: "saltHex",
            secretBlock: Data("secretBlock".utf8),
            serverPublicBHexString: "serverPublicBHexString",
            srpClient: srpClient
        )
    }
}

private class MockSRPClientBehavior: SRPClientBehavior {
    var kHexValue: String = "kHexValue"
    
    static func calculateUHexValue(
        clientPublicKeyHexValue: String,
        serverPublicKeyHexValue: String
    ) throws -> String {
        return "UHexValue"
    }

    static var authenticationKey: Result<Data, Error> = .success(Data("AuthenticationKey".utf8))
    static func generateAuthenticationKey(
        sharedSecretHexValue: String,
        uHexValue: String
    ) throws -> Data {
        return try authenticationKey.get()
    }
    
    static func reset() {
        authenticationKey = .success(Data("AuthenticationKey".utf8))
    }
    
    func generateClientKeyPair() -> SRPKeys {
        return .init(
            publicKeyHexValue: "publicKeyHexValue",
            privateKeyHexValue: "privateKeyHexValue"
        )
    }
    
    var sharedSecret: Result<String, Error> = .success("SharedSecret")
    func calculateSharedSecret(
        username: String,
        password: String,
        saltHexValue: String,
        clientPrivateKeyHexValue: String,
        clientPublicKeyHexValue: String,
        serverPublicKeyHexValue: String
    ) throws -> String {
        return try sharedSecret.get()
    }
    
    func generateDevicePasswordVerifier(
        deviceGroupKey: String,
        deviceKey: String,
        password: String
    ) -> (salt: Data, passwordVerifier: Data) {
        return (salt: Data(), passwordVerifier: Data())
    }
}
