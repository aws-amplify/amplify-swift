//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import XCTest

/// The plugin's `AuthStressTests.testMultipleFetchUserAttributes`, through the client (ST-1). A suite of
/// its own, beside `StressTests` (ST-2 … ST-5).
final class UserAttributesStressTests: ClientIntegrationTestCase {

    /// The plugin's `concurrencyLimit`.
    private let concurrencyLimit = 50

    /// Fifty concurrent fetches of the user's attributes all succeed within the plugin's 30 seconds (ST-1).
    ///
    /// - Given: a fresh user with an email, signed in
    /// - When:
    ///    - the client fetches the user's attributes from 50 concurrent tasks
    /// - Then:
    ///    - all 50 finish within 30 seconds, as the plugin's expectation requires
    ///    - every fetch succeeds, and returns the signed-up email
    ///
    func testMultipleFetchUserAttributes() async throws {
        let (client, user) = try await makeSignedInFreshUser("st-1")
        let email = try XCTUnwrap(user.email)
        let fetched = expectation(description: "every fetch of the user attributes finished")
        fetched.expectedFulfillmentCount = concurrencyLimit
        let outcomes = FetchOutcomes()

        for _ in 1 ... concurrencyLimit {
            Task {
                do {
                    let attributes = try await client.fetchUserAttributes()
                    outcomes.record(attributes.first { $0.key == .email }?.value == email ? nil : "a different email")
                } catch {
                    outcomes.record(ClientErrorShape.of(error))
                }
                fetched.fulfill()
            }
        }
        await fulfillment(of: [fetched], timeout: 30)

        XCTAssertEqual(outcomes.count, concurrencyLimit)
        XCTAssertEqual(outcomes.failures, [], "every fetch returns the signed-up email")
    }
}

/// What the concurrent fetches found: a failure's shape, or `nil` for a fetch that returned the email.
private final class FetchOutcomes: @unchecked Sendable {
    private let lock = NSLock()
    private var outcomes: [String?] = []

    func record(_ failure: String?) {
        lock.withLock { outcomes.append(failure) }
    }

    var count: Int {
        lock.withLock { outcomes.count }
    }

    var failures: [String] {
        lock.withLock { outcomes.compactMap { $0 } }
    }
}
