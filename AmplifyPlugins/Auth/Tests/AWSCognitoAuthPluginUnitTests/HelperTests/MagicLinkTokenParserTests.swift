//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin

class MagicLinkTokenParserTests: XCTestCase {

    /// Given: A valid Magic Link Token
    /// When: MagicLinkTokenParser.extractUserName is invoked
    /// Then: A non-empty username string is returned
    func testUsernameExtractionSuccess() throws {
        let token = "eyJ1c2VybmFtZSI6InRlc3RAZXhhbXBsZS5jb20iLCJpYXQiOjE3MDExODkwODksImV4cCI6MTcwMTE4OTY4OX0.AQIDBAUGBwgJ"
        let username = try MagicLinkTokenParser.extractUserName(from: token)
        XCTAssertNotNil(username)
        XCTAssertEqual(username, "test@example.com")
    }

    /// Given: A valid Magic Link Token with empty username
    /// When: MagicLinkTokenParser.extractUserName is invoked
    /// Then: A empty username string is returned
    func testExtractionOfEmptyUsername() throws {
        let token = "eyJ1c2VybmFtZSI6IiIsImlhdCI6MTcwMTE4OTIyMiwiZXhwIjoxNzAxMTg5ODIyfQ.AQIDBAUGBwgJ"
        let username = try MagicLinkTokenParser.extractUserName(from: token)
        XCTAssertNotNil(username)
        XCTAssertEqual(username, "")
    }

    /// Given: A invalid Magic Link Token
    /// When: MagicLinkTokenParser.extractUserName is invoked
    /// Then: A SignInError should be thrown with missing username message
    func testUsernameExtractionFailureWhenMissingUsername() throws {
        let token = "eyJpYXQiOjE3MDExODkyNjcsImV4cCI6MTcwMTE4OTg2N30.AQIDBAUGBwgJ"
        do {
            _ = try MagicLinkTokenParser.extractUserName(from: token)
            XCTFail("Extraction of username should not pass")
        } catch SignInError.invalidServiceResponse(let message) {
            XCTAssertNotNil(message)
            XCTAssertEqual(message, "Did not find username object in magic link token")
        } catch {
            XCTFail("Error should be of type Sign In Error")
        }
    }

    /// Given: A invalid Magic Link Token which is malformed
    /// When: MagicLinkTokenParser.extractUserName is invoked
    /// Then: A SignInError should be thrown with malformed error
    func testUsernameExtractionFailureWhenTokenMalformed() throws {
        let token = "eyJpYXQiOjE3MDExODkyNjcsImV4cCI6MTcwMTE4OTg2N30"
        do {
            _ = try MagicLinkTokenParser.extractUserName(from: token)
            XCTFail("Extraction of username should not pass")
        } catch SignInError.invalidServiceResponse(let message) {
            XCTAssertNotNil(message)
            XCTAssertEqual(message, "Malformed magic link token")
        } catch {
            XCTFail("Error should be of type Sign In Error")
        }
    }

    /// Given: A invalid Magic Link Token with bad data
    /// When: MagicLinkTokenParser.extractUserName is invoked
    /// Then: A SignInError should be thrown with unable to decode message
    func testUsernameExtractionFailureWithBadTokenData() throws {
        let token = "badData.badData"
        do {
            _ = try MagicLinkTokenParser.extractUserName(from: token)
            XCTFail("Extraction of username should not pass")
        } catch SignInError.invalidServiceResponse(let message) {
            XCTAssertNotNil(message)
            XCTAssertEqual(message, "Unable to to decode magic link token")
        } catch {
            XCTFail("Error should be of type Sign In Error")
        }
    }
}
