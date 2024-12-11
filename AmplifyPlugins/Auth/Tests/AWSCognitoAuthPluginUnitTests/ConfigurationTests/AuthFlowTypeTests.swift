//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable import AWSCognitoAuthPlugin

class AuthFlowTypeTests: XCTestCase {

    func testRawValue() {
        XCTAssertEqual(AuthFlowType.userSRP.rawValue, "USER_SRP_AUTH")
        XCTAssertEqual(AuthFlowType.customWithSRP.rawValue, "CUSTOM_AUTH_WITH_SRP")
        XCTAssertEqual(AuthFlowType.customWithoutSRP.rawValue, "CUSTOM_AUTH_WITHOUT_SRP")
        XCTAssertEqual(AuthFlowType.userPassword.rawValue, "USER_PASSWORD_AUTH")
        XCTAssertEqual(AuthFlowType.userAuth(preferredFirstFactor: nil).rawValue, "USER_AUTH")
    }

    func testInitWithRawValue() {
        XCTAssertEqual(AuthFlowType(rawValue: "USER_SRP_AUTH"), .userSRP)
        XCTAssertEqual(AuthFlowType(rawValue: "CUSTOM_AUTH"), .customWithSRP)
        XCTAssertEqual(AuthFlowType(rawValue: "CUSTOM_AUTH_WITH_SRP"), .customWithSRP)
        XCTAssertEqual(AuthFlowType(rawValue: "CUSTOM_AUTH_WITHOUT_SRP"), .customWithoutSRP)
        XCTAssertEqual(AuthFlowType(rawValue: "USER_PASSWORD_AUTH"), .userPassword)
        XCTAssertEqual(AuthFlowType(rawValue: "USER_AUTH"), .userAuth(preferredFirstFactor: nil))
        XCTAssertNil(AuthFlowType(rawValue: "INVALID_AUTH"))
    }

    func testDeprecatedCustom() {
        // This test is to ensure the deprecated case is still functional
        XCTAssertEqual(AuthFlowType.custom.rawValue, "CUSTOM_AUTH_WITH_SRP")
    }

    func testEncoding() throws {
        let encoder = JSONEncoder()
        let userSRP = try encoder.encode(AuthFlowType.userSRP)
        XCTAssertEqual(String(data: userSRP, encoding: .utf8), "{\"type\":\"USER_SRP_AUTH\"}")

        let customWithSRP = try encoder.encode(AuthFlowType.customWithSRP)
        XCTAssertEqual(String(data: customWithSRP, encoding: .utf8), "{\"type\":\"CUSTOM_AUTH_WITH_SRP\"}")

        let customWithoutSRP = try encoder.encode(AuthFlowType.customWithoutSRP)
        XCTAssertEqual(String(data: customWithoutSRP, encoding: .utf8), "{\"type\":\"CUSTOM_AUTH_WITHOUT_SRP\"}")

        let userPassword = try encoder.encode(AuthFlowType.userPassword)
        XCTAssertEqual(String(data: userPassword, encoding: .utf8), "{\"type\":\"USER_PASSWORD_AUTH\"}")

        let userAuth = try encoder.encode(AuthFlowType.userAuth(preferredFirstFactor: nil))
        XCTAssertTrue(String(data: userAuth, encoding: .utf8)?.contains("\"preferredFirstFactor\":null") == true)
        XCTAssertTrue(String(data: userAuth, encoding: .utf8)?.contains("\"type\":\"USER_AUTH\"") == true)
    }

    func testDecoding() throws {
        let decoder = JSONDecoder()
        let userSRP = try decoder.decode(AuthFlowType.self, from: "{\"type\":\"USER_SRP_AUTH\"}".data(using: .utf8)!)
        XCTAssertEqual(userSRP, .userSRP)

        let customWithSRP = try decoder.decode(AuthFlowType.self, from: "{\"type\":\"CUSTOM_AUTH_WITH_SRP\"}".data(using: .utf8)!)
        XCTAssertEqual(customWithSRP, .customWithSRP)

        let customWithoutSRP = try decoder.decode(AuthFlowType.self, from: "{\"type\":\"CUSTOM_AUTH_WITHOUT_SRP\"}".data(using: .utf8)!)
        XCTAssertEqual(customWithoutSRP, .customWithoutSRP)

        let userPassword = try decoder.decode(AuthFlowType.self, from: "{\"type\":\"USER_PASSWORD_AUTH\"}".data(using: .utf8)!)
        XCTAssertEqual(userPassword, .userPassword)

        let userAuth = try decoder.decode(AuthFlowType.self, from: "{\"type\":\"USER_AUTH\"}".data(using: .utf8)!)
        XCTAssertEqual(userAuth, .userAuth(preferredFirstFactor: nil))
    }

    func testDecodingWithPreferredFirstFactor() throws {
        let decoder = JSONDecoder()
        let json = """
        {
            "type": "USER_AUTH",
            "preferredFirstFactor": "SMS_OTP"
        }
        """.data(using: .utf8)!
        let authFlowType = try decoder.decode(AuthFlowType.self, from: json)
        XCTAssertEqual(authFlowType, .userAuth(preferredFirstFactor: .smsOTP))
    }

    func testDecodingLegacyStructure() throws {
        let decoder = JSONDecoder()
        var legacyJson = "\"userSRP\"".data(using: .utf8)!
        var authFlowType = try decoder.decode(AuthFlowType.self, from: legacyJson)
        XCTAssertEqual(authFlowType, .userSRP)

        legacyJson = "\"userPassword\"".data(using: .utf8)!
        authFlowType = try decoder.decode(AuthFlowType.self, from: legacyJson)
        XCTAssertEqual(authFlowType, .userPassword)

        legacyJson = "\"customWithSRP\"".data(using: .utf8)!
        authFlowType = try decoder.decode(AuthFlowType.self, from: legacyJson)
        XCTAssertEqual(authFlowType, .customWithSRP)

        legacyJson = "\"customWithoutSRP\"".data(using: .utf8)!
        authFlowType = try decoder.decode(AuthFlowType.self, from: legacyJson)
        XCTAssertEqual(authFlowType, .customWithoutSRP)

        legacyJson = "\"custom\"".data(using: .utf8)!
        authFlowType = try decoder.decode(AuthFlowType.self, from: legacyJson)
        XCTAssertEqual(authFlowType, .custom)
    }

    func testDecodingInvalidType() {
        let decoder = JSONDecoder()
        let invalidJson = "{\"type\":\"INVALID_AUTH\"}".data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(AuthFlowType.self, from: invalidJson)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                return XCTFail("Expected dataCorrupted error")
            }
            XCTAssertEqual(context.debugDescription, "Invalid AuthFlowType value")
        }
    }

    func testDecodingInvalidPreferredFirstFactor() {
        let decoder = JSONDecoder()
        let invalidJson = """
        {
            "type": "USER_AUTH",
            "preferredFirstFactor": "INVALID_FACTOR"
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(AuthFlowType.self, from: invalidJson)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                return XCTFail("Expected dataCorrupted error")
            }
            XCTAssertEqual(context.debugDescription, "Unable to decode preferredFirstFactor value")
        }
    }

    func testGetClientFlowType() {
        XCTAssertEqual(AuthFlowType.custom.getClientFlowType(), .customAuth)
        XCTAssertEqual(AuthFlowType.customWithSRP.getClientFlowType(), .customAuth)
        XCTAssertEqual(AuthFlowType.customWithoutSRP.getClientFlowType(), .customAuth)
        XCTAssertEqual(AuthFlowType.userSRP.getClientFlowType(), .userSrpAuth)
        XCTAssertEqual(AuthFlowType.userPassword.getClientFlowType(), .userPasswordAuth)
        XCTAssertEqual(AuthFlowType.userAuth(preferredFirstFactor: nil).getClientFlowType(), .userAuth)
    }
}
