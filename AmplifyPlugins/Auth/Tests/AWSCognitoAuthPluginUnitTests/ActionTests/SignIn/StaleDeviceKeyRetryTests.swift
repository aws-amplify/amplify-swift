//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The sign-in actions that send a device key to Cognito in their first request drop a key Cognito no longer knows
/// (the device was forgotten, and `forgetDevice` keeps the local record) and send the request once more without it,
/// as the SRP flow's password verifier does.
final class StaleDeviceKeyRetryTests: XCTestCase {

    private let staleDevice = DeviceMetadata.metadata(.init(deviceKey: "stale-key", deviceGroupKey: "group", deviceSecret: "secret"))

    /// - Given: Cognito refusing any request that carries a device key with `ResourceNotFoundException` ("Device does
    ///   not exist."), and each of the password (`USER_PASSWORD_AUTH`), password-in-`USER_AUTH`, `USER_AUTH` and custom
    ///   sign-in actions holding the stale device key
    /// - When: each action runs
    /// - Then:
    ///    - it sends its request twice, the first with the stale key and the second with none, and dispatches the
    ///      second's outcome, not an error
    func testEachFlowRetriesOnceWithoutAStaleDeviceKey() async throws {
        for (name, flow) in flows {
            let requests = DeviceKeyRecorder()
            let environment = Defaults.makeDefaultAuthEnvironment(userPoolFactory: {
                Self.userPool(requests, refusingOnlyDeviceKeys: true)
            })

            let events = await run(flow, environment)

            XCTAssertEqual(requests.deviceKeys, ["stale-key", nil], name)
            XCTAssertFalse(events.contains(where: Self.isAuthError), "\(name): \(events)")
        }
    }

    /// - Given: Cognito refusing every request with `ResourceNotFoundException`, and each action holding the stale
    ///   device key, then holding none
    /// - When: each action runs
    /// - Then:
    ///    - with the stale key it retries only once, then dispatches the error; with no key it sends one request and
    ///      dispatches the error: a `ResourceNotFoundException` without a device key is not about a device
    func testTheRetryHappensOnceAndOnlyForASentDeviceKey() async throws {
        for (name, flow) in flows {
            for device in [staleDevice, .noData] {
                let requests = DeviceKeyRecorder()
                let environment = Defaults.makeDefaultAuthEnvironment(userPoolFactory: {
                    Self.userPool(requests, refusingOnlyDeviceKeys: false)
                })

                let events = await run(flow, environment, device: device)

                let expected: [String?]
                if case .metadata = device {
                    expected = ["stale-key", nil]
                } else {
                    expected = [nil]
                }
                XCTAssertEqual(requests.deviceKeys, expected, name)
                XCTAssertTrue(events.contains(where: Self.isAuthError), "\(name): \(events)")
            }
        }
    }

    // MARK: Helpers

    private typealias Flow = @Sendable (DeviceMetadata) -> any Action

    private var flows: [(String, Flow)] {
        [
            ("password", { device in
                InitiateMigrateAuth(username: "alice", password: "password", clientMetadata: [:], deviceMetadata: device, respondToAuthChallenge: nil)
            }),
            ("password in USER_AUTH", { device in
                InitiateMigrateAuth(
                    username: "alice",
                    password: "password",
                    clientMetadata: [:],
                    deviceMetadata: device,
                    respondToAuthChallenge: RespondToAuthChallenge(
                        challenge: .password,
                        availableChallenges: [],
                        username: "alice",
                        session: "session",
                        parameters: [:]
                    )
                )
            }),
            ("USER_AUTH", { device in
                InitiateUserAuth(
                    signInEventData: SignInEventData(username: "alice", password: nil, signInMethod: .apiBased(.userAuth(preferredFirstFactor: nil))),
                    deviceMetadata: device
                )
            }),
            ("custom", { device in
                InitiateCustomAuth(username: "alice", clientMetadata: [:], deviceMetadata: device)
            })
        ]
    }

    private func run(_ flow: Flow, _ environment: AuthEnvironment, device: DeviceMetadata? = nil) async -> [StateMachineEvent] {
        let events = DispatchedEvents()
        await flow(device ?? staleDevice).execute(withDispatcher: MockDispatcher { events.record($0) }, environment: environment)
        return events.events
    }

    private static func isAuthError(_ event: StateMachineEvent) -> Bool {
        guard let event = event as? SignInEvent, case .throwAuthError = event.eventType else {
            return false
        }
        return true
    }

    /// A user pool that records each request's device key. With `refusingOnlyDeviceKeys`, it refuses only requests with
    /// a device key and signs the others in; otherwise it refuses every request.
    private static func userPool(_ requests: DeviceKeyRecorder, refusingOnlyDeviceKeys: Bool) -> MockIdentityProvider {
        let tokens = CognitoIdentityProviderClientTypes.AuthenticationResultType(
            accessToken: Defaults.validAccessToken,
            expiresIn: 3_600,
            idToken: "idToken",
            refreshToken: "refreshToken"
        )
        let answer: @Sendable (String?) throws -> Void = { deviceKey in
            requests.record(deviceKey)
            if deviceKey != nil || !refusingOnlyDeviceKeys {
                throw AWSCognitoIdentityProvider.ResourceNotFoundException(message: "Device does not exist.")
            }
        }
        return MockIdentityProvider(
            mockInitiateAuthResponse: { input in
                try answer(input.authParameters?["DEVICE_KEY"])
                return InitiateAuthOutput(authenticationResult: tokens)
            },
            mockRespondToAuthChallengeResponse: { input in
                try answer(input.challengeResponses?["DEVICE_KEY"])
                return RespondToAuthChallengeOutput(authenticationResult: tokens)
            }
        )
    }
}

/// The device key of each request, in order.
private final class DeviceKeyRecorder: @unchecked Sendable {
    // `@unchecked Sendable`: `keys` is only touched while holding `lock`.
    private let lock = NSLock()
    private var keys: [String?] = []

    var deviceKeys: [String?] {
        lock.withLock { keys }
    }

    func record(_ key: String?) {
        lock.withLock { keys.append(key) }
    }
}

/// The events an action dispatched, in order.
private final class DispatchedEvents: @unchecked Sendable {
    // `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
    private let lock = NSLock()
    private var recorded: [StateMachineEvent] = []

    var events: [StateMachineEvent] {
        lock.withLock { recorded }
    }

    func record(_ event: StateMachineEvent) {
        lock.withLock { recorded.append(event) }
    }
}
