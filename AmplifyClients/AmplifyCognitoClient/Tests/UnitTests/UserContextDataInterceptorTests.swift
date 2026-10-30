//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoASF
import AWSClientRuntime
import AWSCognitoIdentityProvider
import ClientRuntime
import CryptoKit
import Foundation
import Smithy
import SmithyHTTPAPI
import SmithyIdentity
import SmithyRetriesAPI
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `CognitoUserContextData.interceptorProvider(deviceId:)` on a real `CognitoIdentityProviderClient`, whose HTTP
/// engine keeps each request. Every test but the macOS one uses a fixed device, so none reads `UIDevice` or
/// `UIScreen`.
final class UserContextDataInterceptorTests: XCTestCase {

    private static let userPoolId = "us-east-1_EXAMPLE"
    private static let clientId = "1example23456789abcdefghij"
    private static let otherClientId = "2other3456789abcdefghijklm"
    private static let vendorId = "00000000-0000-4000-8000-000000000047"
    private static let contextData = CognitoUserContextData(userPoolId: userPoolId, userPoolClientId: clientId)

    // MARK: - The seven operations

    /// Test that InitiateAuth gets user context data for the user it names
    ///
    /// - Given: A real `CognitoIdentityProviderClient` with the interceptor provider added once to its configuration
    /// - When:
    ///    - `initiateAuth` is called without `userContextData`
    /// - Then:
    ///    - the request carries `UserContextData.EncodedData`, signed with the app client ID, naming the pool, the
    ///      `USERNAME` in `AuthParameters` and a time during the call, with the plain function's context data
    ///
    func testInitiateAuthGetsContextDataForItsUser() async throws {
        try await assertTheOperationGetsContextDataForItsUser(.initiateAuth)
    }

    /// Test that RespondToAuthChallenge gets user context data for the user it names
    ///
    /// - Given: A real `CognitoIdentityProviderClient` with the interceptor provider added once to its configuration
    /// - When:
    ///    - `respondToAuthChallenge` is called without `userContextData`
    /// - Then:
    ///    - the request carries signed encoded data naming the pool and the `USERNAME` in `ChallengeResponses`
    ///
    func testRespondToAuthChallengeGetsContextDataForItsUser() async throws {
        try await assertTheOperationGetsContextDataForItsUser(.respondToAuthChallenge)
    }

    /// Test that SignUp gets user context data for the user it names
    ///
    /// - Given: A real `CognitoIdentityProviderClient` with the interceptor provider added once to its configuration
    /// - When:
    ///    - `signUp` is called without `userContextData`
    /// - Then:
    ///    - the request carries signed encoded data naming the pool and the request's `Username`
    ///
    func testSignUpGetsContextDataForItsUser() async throws {
        try await assertTheOperationGetsContextDataForItsUser(.signUp)
    }

    /// Test that ConfirmSignUp gets user context data for the user it names
    ///
    /// - Given: A real `CognitoIdentityProviderClient` with the interceptor provider added once to its configuration
    /// - When:
    ///    - `confirmSignUp` is called without `userContextData`
    /// - Then:
    ///    - the request carries signed encoded data naming the pool and the request's `Username`
    ///
    func testConfirmSignUpGetsContextDataForItsUser() async throws {
        try await assertTheOperationGetsContextDataForItsUser(.confirmSignUp)
    }

    /// Test that ForgotPassword gets user context data for the user it names
    ///
    /// - Given: A real `CognitoIdentityProviderClient` with the interceptor provider added once to its configuration
    /// - When:
    ///    - `forgotPassword` is called without `userContextData`
    /// - Then:
    ///    - the request carries signed encoded data naming the pool and the request's `Username`
    ///
    func testForgotPasswordGetsContextDataForItsUser() async throws {
        try await assertTheOperationGetsContextDataForItsUser(.forgotPassword)
    }

    /// Test that ConfirmForgotPassword gets user context data for the user it names
    ///
    /// - Given: A real `CognitoIdentityProviderClient` with the interceptor provider added once to its configuration
    /// - When:
    ///    - `confirmForgotPassword` is called without `userContextData`
    /// - Then:
    ///    - the request carries signed encoded data naming the pool and the request's `Username`
    ///
    func testConfirmForgotPasswordGetsContextDataForItsUser() async throws {
        try await assertTheOperationGetsContextDataForItsUser(.confirmForgotPassword)
    }

    /// Test that ResendConfirmationCode gets user context data for the user it names
    ///
    /// - Given: A real `CognitoIdentityProviderClient` with the interceptor provider added once to its configuration
    /// - When:
    ///    - `resendConfirmationCode` is called without `userContextData`
    /// - Then:
    ///    - the request carries signed encoded data naming the pool and the request's `Username`
    ///
    func testResendConfirmationCodeGetsContextDataForItsUser() async throws {
        try await assertTheOperationGetsContextDataForItsUser(.resendConfirmationCode)
    }

    // MARK: - The caller's value

    /// Test that a request whose user context data already has encoded data is sent as it is
    ///
    /// - Given: A client with the interceptor, over a device and an app that fail the test when read, and a device ID
    ///   provider that logs each call
    /// - When:
    ///    - each of the seven operations is called with `userContextData` holding encoded data and an IP address
    /// - Then:
    ///    - each request carries that `UserContextData` unchanged, the device and app are never read, and the provider
    ///      is never asked
    ///
    func testACallerSetEncodedDataIsSentUnchanged() async throws {
        let asked = Recorder<String?>()
        for operation in ContextDataOperation.all {
            let engine = CapturingEngine()
            let cognito = try Self.client(engine: engine, provider: Self.unreadableProvider(deviceId: { username in
                await asked.record(username)
                return "device-id"
            }))

            try await operation(
                cognito,
                clientId: Self.clientId,
                userContextData: .init(encodedData: "caller-encoded-data", ipAddress: "192.0.2.10")
            )

            let requests = await engine.requests
            XCTAssertEqual(requests.count, 1, operation.name)
            let request = try XCTUnwrap(requests.first, operation.name)
            XCTAssertEqual(
                try Decoded.userContextData(request),
                ["EncodedData": "caller-encoded-data", "IpAddress": "192.0.2.10"],
                operation.name
            )
        }
        let usernames = await asked.entries
        XCTAssertEqual(usernames.count, 0)
    }

    /// Test that a request whose user context data has only an IP address, or empty encoded data, gets encoded data
    /// and keeps the address
    ///
    /// - Given: A client with the interceptor, over a fixed device and app
    /// - When:
    ///    - each of the seven operations is called with `userContextData` holding only an IP address, and again with
    ///      empty encoded data and an IP address
    /// - Then:
    ///    - each request carries the IP address and signed encoded data for its user
    ///
    func testACallerSetIpAddressIsKeptAndEncodedDataIsAdded() async throws {
        for operation in ContextDataOperation.all {
            for given in [
                CognitoIdentityProviderClientTypes.UserContextDataType(ipAddress: "192.0.2.10"),
                CognitoIdentityProviderClientTypes.UserContextDataType(encodedData: "", ipAddress: "192.0.2.10")
            ] {
                let engine = CapturingEngine()
                let cognito = try Self.client(engine: engine, provider: Self.fixedProvider())

                try await operation(cognito, clientId: Self.clientId, userContextData: given)

                let requests = await engine.requests
                let request = try XCTUnwrap(requests.first, operation.name)
                let data = try XCTUnwrap(Decoded.userContextData(request), operation.name)
                XCTAssertEqual(Set(data.keys), ["EncodedData", "IpAddress"], operation.name)
                XCTAssertEqual(data["IpAddress"], "192.0.2.10", operation.name)
                let encoded = try Decoded.encodedData(request)
                let payload = try XCTUnwrap(Decoded.envelope(encoded)["payload"], operation.name)
                XCTAssertEqual(
                    try Decoded.envelope(encoded)["signature"],
                    try Decoded.signature(of: payload, clientId: Self.clientId),
                    operation.name
                )
                XCTAssertEqual(try Decoded.payload(encoded)["username"] as? String, operation.username, operation.name)
            }
        }
    }

    // MARK: - Requests left alone

    /// Test that requests without user context data are sent exactly as they are without the interceptor
    ///
    /// - Given: A client with the interceptor, over a device and an app that fail the test when read, and a client
    ///   without it
    /// - When:
    ///    - `getUser`, `globalSignOut` and `adminInitiateAuth` (signed, with `ContextData` rather than
    ///      `UserContextData`) are called on both
    /// - Then:
    ///    - every call succeeds, the device and app are never read, and each parsed JSON body is the same with and
    ///      without the interceptor, with neither `UserContextData` nor `ContextData`
    ///
    func testRequestsWithoutUserContextDataAreUnchanged() async throws {
        let interceptedEngine = CapturingEngine()
        let plainEngine = CapturingEngine()
        let intercepted = try Self.client(engine: interceptedEngine, provider: Self.unreadableProvider())
        let plain = try Self.client(engine: plainEngine)

        for cognito in [intercepted, plain] {
            _ = try await cognito.getUser(input: GetUserInput(accessToken: "access-token"))
            _ = try await cognito.globalSignOut(input: GlobalSignOutInput(accessToken: "access-token"))
            _ = try await cognito.adminInitiateAuth(input: AdminInitiateAuthInput(
                authFlow: .adminUserPasswordAuth,
                authParameters: ["USERNAME": "alice", "PASSWORD": "Passw0rd!"],
                clientId: Self.clientId,
                userPoolId: Self.userPoolId
            ))
        }

        let sent = await interceptedEngine.requests
        let expected = await plainEngine.requests
        XCTAssertEqual(sent.map(\.target), [
            "AWSCognitoIdentityProviderService.GetUser",
            "AWSCognitoIdentityProviderService.GlobalSignOut",
            "AWSCognitoIdentityProviderService.AdminInitiateAuth"
        ])
        XCTAssertEqual(sent.count, expected.count)
        for (request, plainRequest) in zip(sent, expected) {
            let body = try Decoded.body(request)
            XCTAssertEqual(NSDictionary(dictionary: body), NSDictionary(dictionary: try Decoded.body(plainRequest)))
            XCTAssertNil(body["UserContextData"])
            XCTAssertNil(body["ContextData"])
        }
    }

    /// Test that a request for another app client, or for none, is sent as it is
    ///
    /// - Given: A client whose interceptor is for one app client, over a device and an app that fail the test when
    ///   read, and a device ID provider that logs each call
    /// - When:
    ///    - each of the seven operations is called with another app client's ID, and again without a client ID
    /// - Then:
    ///    - every call succeeds, no request carries `UserContextData`, and the provider is never asked
    ///
    func testARequestForAnotherAppClientIsUnchanged() async throws {
        let engine = CapturingEngine()
        let asked = Recorder<String?>()
        let cognito = try Self.client(engine: engine, provider: Self.unreadableProvider(deviceId: { username in
            await asked.record(username)
            return "device-id"
        }))

        for operation in ContextDataOperation.all {
            try await operation(cognito, clientId: Self.otherClientId)
            try await operation(cognito, clientId: nil)
        }

        let requests = await engine.requests
        XCTAssertEqual(requests.count, 14)
        for request in requests {
            XCTAssertNil(try Decoded.userContextData(request), request.target ?? "")
        }
        let usernames = await asked.entries
        XCTAssertEqual(usernames.count, 0)
    }

    /// Test that an empty user pool or app client ID adds nothing, without reading the device or asking for a
    /// device ID, and the request still succeeds
    ///
    /// - Given: Clients whose interceptor has an empty user pool ID, or an empty app client ID, over a device and an
    ///   app that fail the test when read and a device ID provider that logs each call, and one from the public
    ///   method with an empty user pool ID
    /// - When:
    ///    - each of the seven operations is called on each, with the interceptor's app client ID
    /// - Then:
    ///    - every call succeeds, no request carries `UserContextData`, and the provider is never asked
    ///
    func testAnEmptyIdAddsNothingAndTheRequestSucceeds() async throws {
        let engine = CapturingEngine()
        let asked = Recorder<String?>()
        let deviceId: UserContextDataInterceptorProvider.DeviceIdProvider = { username in
            await asked.record(username)
            return "device-id"
        }
        let withoutPool = CognitoUserContextData(userPoolId: "", userPoolClientId: Self.clientId)
        let withoutClient = CognitoUserContextData(userPoolId: Self.userPoolId, userPoolClientId: "")
        let clients = try [
            (Self.client(engine: engine, provider: Self.unreadableProvider(withoutPool, deviceId: deviceId)), Self.clientId),
            (Self.client(engine: engine, provider: Self.unreadableProvider(withoutClient, deviceId: deviceId)), ""),
            (Self.client(engine: engine, provider: withoutPool.interceptorProvider(deviceId: deviceId)), Self.clientId)
        ]

        for (cognito, clientId) in clients {
            for operation in ContextDataOperation.all {
                try await operation(cognito, clientId: clientId)
            }
        }

        let requests = await engine.requests
        XCTAssertEqual(requests.count, 21)
        for request in requests {
            XCTAssertNil(try Decoded.userContextData(request), request.target ?? "")
        }
        let usernames = await asked.entries
        XCTAssertEqual(usernames.count, 0)
    }

    /// Test that data that can't be encoded leaves the request as it is, and the call succeeds
    ///
    /// - Given: A client whose interceptor's app client ID isn't ASCII, so it can't key the signature
    /// - When:
    ///    - `initiateAuth` is called with that client ID
    /// - Then:
    ///    - the call succeeds, and the request has no `UserContextData`
    ///
    func testDataThatCannotBeEncodedLeavesTheRequestUnchanged() async throws {
        let engine = CapturingEngine()
        let contextData = CognitoUserContextData(userPoolId: Self.userPoolId, userPoolClientId: "🕺🏼")
        let cognito = try Self.client(engine: engine, provider: Self.fixedProvider(contextData))

        try await ContextDataOperation.initiateAuth(cognito, clientId: "🕺🏼")

        let requests = await engine.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertNil(try Decoded.userContextData(request))
    }

    // MARK: - Usernames

    /// Test what a refresh-token sign-in sends, as its request names no user
    ///
    /// - Given: A client with the interceptor and a device ID provider that logs the usernames it is given
    /// - When:
    ///    - `initiateAuth` is called with `REFRESH_TOKEN_AUTH` and only `REFRESH_TOKEN` in `AuthParameters`
    /// - Then:
    ///    - the request still carries signed encoded data, naming the user "unknown", as the plain function does for
    ///      a `nil` username
    ///    - the device ID provider is asked once, with `nil`
    ///
    func testARefreshTokenSignInNamesAnUnknownUser() async throws {
        let engine = CapturingEngine()
        let asked = Recorder<String?>()
        let cognito = try Self.client(engine: engine, provider: Self.fixedProvider(deviceId: { username in
            await asked.record(username)
            return nil
        }))

        _ = try await cognito.initiateAuth(input: InitiateAuthInput(
            authFlow: .refreshTokenAuth,
            authParameters: ["REFRESH_TOKEN": "refresh-token"],
            clientId: Self.clientId
        ))

        let requests = await engine.requests
        let request = try XCTUnwrap(requests.first)
        let encoded = try Decoded.encodedData(request)
        let payload = try XCTUnwrap(Decoded.envelope(encoded)["payload"])
        XCTAssertEqual(try Decoded.envelope(encoded)["signature"], try Decoded.signature(of: payload, clientId: Self.clientId))
        XCTAssertEqual(try Decoded.payload(encoded)["username"] as? String, "unknown")
        let usernames = await asked.entries
        XCTAssertEqual(usernames, [nil])
    }

    // MARK: - Device IDs

    /// Test that the device ID provider's answer is the device ID of every one of the seven operations
    ///
    /// - Given: A client with the interceptor and a device ID provider that answers with an ID for each username
    /// - When:
    ///    - each of the seven operations is called
    /// - Then:
    ///    - the provider is asked once per call, with the call's username
    ///    - each request's `DeviceId` is the provider's answer, and its `ThirdPartyDeviceId` is still the vendor ID
    ///
    func testTheDeviceIdProviderAnswersForEveryOperation() async throws {
        let engine = CapturingEngine()
        let asked = Recorder<String?>()
        let cognito = try Self.client(engine: engine, provider: Self.fixedProvider(deviceId: { username in
            await asked.record(username)
            return "device-of-\(username ?? "nobody")"
        }))

        for operation in ContextDataOperation.all {
            try await operation(cognito, clientId: Self.clientId)
        }

        let requests = await engine.requests
        let usernames = await asked.entries
        XCTAssertEqual(usernames, ContextDataOperation.all.map { Optional($0.username) })
        XCTAssertEqual(requests.count, ContextDataOperation.all.count)
        for (request, operation) in zip(requests, ContextDataOperation.all) {
            let contextData = try Decoded.contextData(Decoded.encodedData(request))
            XCTAssertEqual(contextData["DeviceId"], "device-of-\(operation.username)", operation.name)
            XCTAssertEqual(contextData["ThirdPartyDeviceId"], Self.vendorId, operation.name)
        }
    }

    /// Test that without a device ID from the provider the vendor ID is sent in its place
    ///
    /// - Given: A client with the interceptor and a device ID provider that answers for one user only
    /// - When:
    ///    - `initiateAuth` is called for that user, and `signUp` for another
    /// - Then:
    ///    - the first request's `DeviceId` is the provider's answer, and the second's is the vendor ID
    ///
    func testWithoutADeviceIdFromTheProviderTheVendorIdIsSent() async throws {
        let engine = CapturingEngine()
        let cognito = try Self.client(engine: engine, provider: Self.fixedProvider(deviceId: { username in
            username == "alice" ? "us-east-1_device-key-of-alice" : nil
        }))

        try await ContextDataOperation.initiateAuth(cognito, clientId: Self.clientId)
        try await ContextDataOperation.signUp(cognito, clientId: Self.clientId)

        let requests = await engine.requests
        let alice = try Decoded.contextData(Decoded.encodedData(requests[0]))
        let carol = try Decoded.contextData(Decoded.encodedData(requests[1]))
        XCTAssertEqual(alice["DeviceId"], "us-east-1_device-key-of-alice")
        XCTAssertEqual(carol["DeviceId"], Self.vendorId)
        XCTAssertEqual(carol["ThirdPartyDeviceId"], Self.vendorId)
    }

    // MARK: - Retries and concurrency

    /// Test that a retried call resends the data made once for the call
    ///
    /// - Given: An engine whose first reply is HTTP 500 `InternalErrorException`, and a client with the interceptor
    ///   over a device that logs its reads, and with a probe interceptor that logs two of its hooks
    /// - When:
    ///    - `initiateAuth` is called
    /// - Then:
    ///    - the call succeeds on the second attempt
    ///    - the device is read once, `modifyBeforeSerialization` runs once and `readBeforeAttempt` twice
    ///    - both attempts send the same body, so the same encoded data and timestamp
    ///
    func testARetriedCallResendsTheDataMadeOnceForTheCall() async throws {
        let engine = CapturingEngine(replies: [.internalError])
        let reads = Recorder<String>()
        let hooks = Recorder<String>()
        let cognito = try Self.client(engine: engine) { config in
            config.addInterceptorProvider(UserContextDataInterceptorProvider(
                contextData: Self.contextData,
                device: { _ in LoggingDevice(reads: reads) },
                appInfo: { FixedAppInfo() }
            ))
            config.addInterceptorProvider(HookProbe(log: hooks))
        }

        try await ContextDataOperation.initiateAuth(cognito, clientId: Self.clientId)

        let requests = await engine.requests
        let readCount = await reads.entries.count
        let hookLog = await hooks.entries
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(readCount, 1)
        XCTAssertEqual(hookLog.count(where: { $0 == "modifyBeforeSerialization" }), 1)
        XCTAssertEqual(hookLog.count(where: { $0 == "readBeforeAttempt" }), 2)
        XCTAssertEqual(requests.first?.body, requests.last?.body)
        XCTAssertEqual(try Decoded.encodedData(requests[0]), try Decoded.encodedData(requests[1]))
    }

    /// Test that a call that fails every attempt sends the same data each time and throws the service's error
    ///
    /// - Given: An engine that replies HTTP 500 `InternalErrorException` to every attempt, and a client with the
    ///   interceptor over a device that logs its reads
    /// - When:
    ///    - `initiateAuth` is called
    /// - Then:
    ///    - it throws `InternalErrorException` after three attempts with the same body, and the device is read once
    ///
    func testACallThatFailsEveryAttemptThrowsTheServicesError() async throws {
        let engine = CapturingEngine(replies: [.internalError, .internalError, .internalError])
        let reads = Recorder<String>()
        let cognito = try Self.client(engine: engine, provider: UserContextDataInterceptorProvider(
            contextData: Self.contextData,
            device: { _ in LoggingDevice(reads: reads) },
            appInfo: { FixedAppInfo() }
        ))

        do {
            try await ContextDataOperation.initiateAuth(cognito, clientId: Self.clientId)
            XCTFail("The call succeeded")
        } catch {
            XCTAssertTrue(error is InternalErrorException, "\(type(of: error)): \(error)")
        }

        let requests = await engine.requests
        let readCount = await reads.entries.count
        XCTAssertEqual(requests.count, 3)
        XCTAssertEqual(Set(requests.map(\.body)).count, 1)
        XCTAssertEqual(readCount, 1)
        XCTAssertNotNil(try Decoded.userContextData(requests[0]))
    }

    /// Test that concurrent calls through one client each get data for their own user
    ///
    /// - Given: One client with the interceptor
    /// - When:
    ///    - 24 `initiateAuth` calls, each for a different user, run at once
    /// - Then:
    ///    - each request's data names that request's `USERNAME` and is signed with the app client ID
    ///
    func testConcurrentCallsEachGetDataForTheirOwnUser() async throws {
        let engine = CapturingEngine()
        let clientId = Self.clientId
        let cognito = try Self.client(engine: engine, provider: Self.fixedProvider())
        let usernames = (0 ..< 24).map { "user-\($0)" }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for username in usernames {
                group.addTask {
                    _ = try await cognito.initiateAuth(input: InitiateAuthInput(
                        authFlow: .userPasswordAuth,
                        authParameters: ["USERNAME": username, "PASSWORD": "Passw0rd!"],
                        clientId: clientId
                    ))
                }
            }
            try await group.waitForAll()
        }

        let requests = await engine.requests
        XCTAssertEqual(requests.count, usernames.count)
        var named: [String] = []
        for request in requests {
            let username = try XCTUnwrap((Decoded.body(request)["AuthParameters"] as? [String: String])?["USERNAME"])
            let encoded = try Decoded.encodedData(request)
            let envelope = try Decoded.envelope(encoded)
            let payload = try XCTUnwrap(envelope["payload"])
            XCTAssertEqual(envelope["signature"], try Decoded.signature(of: payload, clientId: clientId))
            XCTAssertEqual(try Decoded.payload(encoded)["username"] as? String, username)
            named.append(username)
        }
        XCTAssertEqual(Set(named), Set(usernames))
    }

    // MARK: - The public method

    /// Test that the public method's provider is for this user pool and app client, and keeps the app's device ID
    /// provider
    ///
    /// - Given: `CognitoUserContextData` for a pool and an app client, and a device ID provider that answers for each
    ///   username
    /// - When:
    ///    - `interceptorProvider(deviceId:)` makes the provider
    /// - Then:
    ///    - it has the same IDs, and its device ID provider gives the app's answer
    ///
    func testThePublicProviderKeepsTheIdsAndTheAppsDeviceIdProvider() async throws {
        let made = Self.contextData.interceptorProvider(deviceId: { username in "device-of-\(username ?? "nobody")" })
        let provider = try XCTUnwrap(made as? UserContextDataInterceptorProvider)

        XCTAssertEqual(provider.contextData.userPoolId, Self.userPoolId)
        XCTAssertEqual(provider.contextData.userPoolClientId, Self.clientId)
        let answer = await provider.deviceId?("alice")
        XCTAssertEqual(answer, "device-of-alice")
    }

    #if os(macOS)
    /// Test that the public method's provider describes the system's device and app
    ///
    /// - Given: A client with `interceptorProvider()`, on macOS, where reading the device never blocks a simulator
    /// - When:
    ///    - `initiateAuth` is called
    /// - Then:
    ///    - the data is signed with the app client ID, names the user and the pool, and carries the main bundle's ID
    ///    - it has no `DeviceId`, as macOS has no identifier for vendor
    ///
    func testThePublicProviderDescribesTheSystemsDeviceAndApp() async throws {
        let engine = CapturingEngine()
        let cognito = try Self.client(engine: engine, provider: Self.contextData.interceptorProvider())

        try await ContextDataOperation.initiateAuth(cognito, clientId: Self.clientId)

        let requests = await engine.requests
        let encoded = try Decoded.encodedData(XCTUnwrap(requests.first))
        let payload = try XCTUnwrap(Decoded.envelope(encoded)["payload"])
        XCTAssertEqual(try Decoded.envelope(encoded)["signature"], try Decoded.signature(of: payload, clientId: Self.clientId))
        let object = try Decoded.payload(encoded)
        XCTAssertEqual(object["username"] as? String, "alice")
        XCTAssertEqual(object["userPoolId"] as? String, Self.userPoolId)
        let contextData = try Decoded.contextData(encoded)
        XCTAssertEqual(contextData["ApplicationName"], Bundle.main.bundleIdentifier)
        XCTAssertNil(contextData["DeviceId"])
    }

    /// Test that the public method's device ID provider is asked, and its answer sent
    ///
    /// - Given: A client with `interceptorProvider(deviceId:)` and a device ID provider that logs the usernames it is
    ///   given, on macOS, where reading the device never blocks a simulator
    /// - When:
    ///    - `initiateAuth` is called
    /// - Then:
    ///    - the provider is asked once with the request's user, and the request's `DeviceId` is its answer
    ///
    func testThePublicProviderSendsTheAppsDeviceId() async throws {
        let engine = CapturingEngine()
        let asked = Recorder<String?>()
        let cognito = try Self.client(engine: engine, provider: Self.contextData.interceptorProvider(deviceId: { username in
            await asked.record(username)
            return "device-of-\(username ?? "nobody")"
        }))

        try await ContextDataOperation.initiateAuth(cognito, clientId: Self.clientId)

        let requests = await engine.requests
        let contextData = try Decoded.contextData(Decoded.encodedData(XCTUnwrap(requests.first)))
        XCTAssertEqual(contextData["DeviceId"], "device-of-alice")
        let usernames = await asked.entries
        XCTAssertEqual(usernames, ["alice"])
    }
    #endif

    // MARK: - Helpers

    private func assertTheOperationGetsContextDataForItsUser(
        _ operation: ContextDataOperation,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let engine = CapturingEngine()
        let cognito = try Self.client(engine: engine, provider: Self.fixedProvider())

        let before = Decoded.milliseconds(Date())
        try await operation(cognito, clientId: Self.clientId)
        let after = Decoded.milliseconds(Date())

        let requests = await engine.requests
        XCTAssertEqual(requests.count, 1, file: file, line: line)
        let request = try XCTUnwrap(requests.first, file: file, line: line)
        XCTAssertEqual(request.target, "AWSCognitoIdentityProviderService.\(operation.name)", file: file, line: line)
        XCTAssertEqual(try Decoded.body(request)["ClientId"] as? String, Self.clientId, file: file, line: line)
        XCTAssertEqual(try Decoded.userContextData(request).map { Set($0.keys) }, ["EncodedData"], file: file, line: line)

        let encoded = try Decoded.encodedData(request)
        let envelope = try Decoded.envelope(encoded)
        XCTAssertEqual(Set(envelope.keys), ["payload", "signature", "version"], file: file, line: line)
        XCTAssertEqual(envelope["version"], "IOS20171114", file: file, line: line)
        let payload = try XCTUnwrap(envelope["payload"], file: file, line: line)
        XCTAssertEqual(
            envelope["signature"],
            try Decoded.signature(of: payload, clientId: Self.clientId),
            file: file,
            line: line
        )

        let object = try Decoded.payload(encoded)
        XCTAssertEqual(Set(object.keys), ["contextData", "username", "userPoolId", "timestamp"], file: file, line: line)
        XCTAssertEqual(object["username"] as? String, operation.username, file: file, line: line)
        XCTAssertEqual(object["userPoolId"] as? String, Self.userPoolId, file: file, line: line)
        let timestamp = try XCTUnwrap(Int64(XCTUnwrap(object["timestamp"] as? String)), file: file, line: line)
        XCTAssertTrue(
            (before ... after).contains(timestamp),
            "\(timestamp) not in \(before)...\(after)",
            file: file,
            line: line
        )

        let plain = await Self.contextData.encodedData(
            username: operation.username,
            deviceId: nil,
            device: FixedASFDevice(id: ""),
            appInfo: FixedAppInfo()
        )
        let contextData = try Decoded.contextData(encoded)
        XCTAssertEqual(contextData, try Decoded.contextData(XCTUnwrap(plain)), file: file, line: line)
        XCTAssertEqual(contextData["DeviceId"], Self.vendorId, file: file, line: line)
    }

    /// A real `CognitoIdentityProviderClient` that sends through `engine`, with fixed fake credentials (only
    /// `AdminInitiateAuth` is signed, locally) and no wait between its three attempts.
    private static func client(
        engine: CapturingEngine,
        provider: (any HttpInterceptorProvider & Sendable)? = nil,
        configure: (inout CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig) -> Void = { _ in }
    ) throws -> CognitoIdentityProviderClient {
        var config = try CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(
            appID: "user-context-data-tests",
            awsCredentialIdentityResolver: StaticAWSCredentialIdentityResolver(
                AWSCredentialIdentity(accessKey: "AKIDEXAMPLE", secret: "not-a-secret")
            ),
            awsRetryMode: .standard,
            ignoreConfiguredEndpointURLs: true,
            region: "us-east-1",
            signingRegion: "us-east-1",
            retryStrategyOptions: RetryStrategyOptions(backoffStrategy: NoBackoff(), maxRetriesBase: 2),
            httpClientEngine: engine
        )
        if let provider {
            config.addInterceptorProvider(provider)
        }
        configure(&config)
        return CognitoIdentityProviderClient(config: config)
    }

    private static func fixedProvider(
        _ contextData: CognitoUserContextData = contextData,
        deviceId: UserContextDataInterceptorProvider.DeviceIdProvider? = nil
    ) -> UserContextDataInterceptorProvider {
        UserContextDataInterceptorProvider(
            contextData: contextData,
            deviceId: deviceId,
            device: { FixedASFDevice(id: $0 ?? "") },
            appInfo: { FixedAppInfo() }
        )
    }

    private static func unreadableProvider(
        _ contextData: CognitoUserContextData = contextData,
        deviceId: UserContextDataInterceptorProvider.DeviceIdProvider? = nil
    ) -> UserContextDataInterceptorProvider {
        UserContextDataInterceptorProvider(
            contextData: contextData,
            deviceId: deviceId,
            device: { _ in UnreadableDevice() },
            appInfo: { UnreadableAppInfo() }
        )
    }
}

/// A request the engine received.
private struct SentRequest: Sendable {
    let target: String?
    let body: Data
}

/// An HTTP engine that keeps every request and answers with the next scripted reply, then with 200 `{}`.
private actor CapturingEngine: HTTPClient {

    struct Reply: Sendable {
        let status: Int
        let headers: [String: String]
        let body: String

        static let ok = Reply(status: 200, headers: [:], body: "{}")
        static let internalError = Reply(
            status: 500,
            headers: ["X-Amzn-ErrorType": "InternalErrorException"],
            body: #"{"__type":"InternalErrorException","message":"Try again"}"#
        )
    }

    private(set) var requests: [SentRequest] = []
    private var replies: [Reply]

    init(replies: [Reply] = []) {
        self.replies = replies
    }

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        let body = try await request.body.readData() ?? Data()
        requests.append(SentRequest(target: request.headers.value(for: "X-Amz-Target"), body: body))
        let reply = replies.isEmpty ? Reply.ok : replies.removeFirst()
        return HTTPResponse(
            headers: Headers(reply.headers),
            body: .data(Data(reply.body.utf8)),
            statusCode: HTTPStatusCode(rawValue: reply.status) ?? .ok
        )
    }
}

/// No wait between retries.
private struct NoBackoff: RetryBackoffStrategy {
    func computeNextBackoffDelay(attempt: Int) -> TimeInterval { 0 }
}

/// One of the seven operations whose input has `userContextData`.
private struct ContextDataOperation: Sendable {
    typealias UserContextData = CognitoIdentityProviderClientTypes.UserContextDataType

    let name: String
    let username: String
    let send: @Sendable (
        _ cognito: CognitoIdentityProviderClient,
        _ clientId: String?,
        _ username: String,
        _ userContextData: UserContextData?
    ) async throws -> Void

    func callAsFunction(
        _ cognito: CognitoIdentityProviderClient,
        clientId: String?,
        userContextData: UserContextData? = nil
    ) async throws {
        try await send(cognito, clientId, username, userContextData)
    }

    static let initiateAuth = Self(name: "InitiateAuth", username: "alice") { cognito, clientId, username, data in
        _ = try await cognito.initiateAuth(input: InitiateAuthInput(
            authFlow: .userSrpAuth,
            authParameters: ["USERNAME": username, "SRP_A": "a1b2c3"],
            clientId: clientId,
            userContextData: data
        ))
    }

    static let respondToAuthChallenge = Self(name: "RespondToAuthChallenge", username: "bob-sub") { cognito, clientId, username, data in
        _ = try await cognito.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .passwordVerifier,
            challengeResponses: [
                "USERNAME": username,
                "PASSWORD_CLAIM_SECRET_BLOCK": "block",
                "PASSWORD_CLAIM_SIGNATURE": "signature",
                "TIMESTAMP": "Thu Oct 30 18:00:00 UTC 2026"
            ],
            clientId: clientId,
            session: "session",
            userContextData: data
        ))
    }

    static let signUp = Self(name: "SignUp", username: "carol") { cognito, clientId, username, data in
        _ = try await cognito.signUp(input: SignUpInput(
            clientId: clientId,
            password: "Passw0rd!",
            userContextData: data,
            username: username
        ))
    }

    static let confirmSignUp = Self(name: "ConfirmSignUp", username: "dave") { cognito, clientId, username, data in
        _ = try await cognito.confirmSignUp(input: ConfirmSignUpInput(
            clientId: clientId,
            confirmationCode: "123456",
            userContextData: data,
            username: username
        ))
    }

    static let forgotPassword = Self(name: "ForgotPassword", username: "erin") { cognito, clientId, username, data in
        _ = try await cognito.forgotPassword(input: ForgotPasswordInput(
            clientId: clientId,
            userContextData: data,
            username: username
        ))
    }

    static let confirmForgotPassword = Self(name: "ConfirmForgotPassword", username: "frank") { cognito, clientId, username, data in
        _ = try await cognito.confirmForgotPassword(input: ConfirmForgotPasswordInput(
            clientId: clientId,
            confirmationCode: "123456",
            password: "Passw0rd!",
            userContextData: data,
            username: username
        ))
    }

    static let resendConfirmationCode = Self(name: "ResendConfirmationCode", username: "grace") { cognito, clientId, username, data in
        _ = try await cognito.resendConfirmationCode(input: ResendConfirmationCodeInput(
            clientId: clientId,
            userContextData: data,
            username: username
        ))
    }

    static let all: [Self] = [
        .initiateAuth,
        .respondToAuthChallenge,
        .signUp,
        .confirmSignUp,
        .forgotPassword,
        .confirmForgotPassword,
        .resendConfirmationCode
    ]
}

/// Reads a sent request's body and the encoded data in it.
private enum Decoded {

    static func body(_ request: SentRequest) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: request.body) as? [String: Any])
    }

    /// `UserContextData` as sent, or `nil` if there is none.
    static func userContextData(_ request: SentRequest) throws -> [String: String]? {
        guard let value = try body(request)["UserContextData"] else {
            return nil
        }
        return try XCTUnwrap(value as? [String: String])
    }

    static func encodedData(_ request: SentRequest) throws -> String {
        try XCTUnwrap(userContextData(request)?["EncodedData"])
    }

    static func envelope(_ encoded: String) throws -> [String: String] {
        let data = try XCTUnwrap(Data(base64Encoded: encoded))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
    }

    static func payload(_ encoded: String) throws -> [String: Any] {
        let payload = try XCTUnwrap(envelope(encoded)["payload"])
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
    }

    static func contextData(_ encoded: String) throws -> [String: String] {
        try XCTUnwrap(payload(encoded)["contextData"] as? [String: String])
    }

    /// base64(HMAC-SHA256(key: the client ID's ASCII bytes, data: "IOS20171114" + payload)).
    static func signature(of payload: String, clientId: String) throws -> String {
        let key = try SymmetricKey(data: XCTUnwrap(clientId.data(using: .ascii)))
        let code = HMAC<SHA256>.authenticationCode(for: Data("IOS20171114\(payload)".utf8), using: key)
        return Data(code).base64EncodedString()
    }

    static func milliseconds(_ date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970 * 1_000)
    }
}

/// Keeps what happens, across tasks.
private actor Recorder<Entry: Sendable> {
    private(set) var entries: [Entry] = []

    func record(_ entry: Entry) {
        entries.append(entry)
    }
}

/// An interceptor that logs when two of its hooks run: once per call, or once per attempt.
private struct HookProbe: HttpInterceptorProvider, Sendable {
    let log: Recorder<String>

    func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
        Probe<InputType, OutputType>(log: log)
    }

    struct Probe<InputType, OutputType>: Interceptor {
        typealias RequestType = HTTPRequest
        typealias ResponseType = HTTPResponse

        let log: Recorder<String>

        func modifyBeforeSerialization(context: some MutableInput<InputType>) async throws {
            await log.record("modifyBeforeSerialization")
        }

        func readBeforeAttempt(context: some AfterSerialization<InputType, HTTPRequest>) async throws {
            await log.record("readBeforeAttempt")
        }
    }
}

/// `FixedASFDevice`, logging each time its fingerprint is read.
private struct LoggingDevice: ASFDeviceBehavior {
    let reads: Recorder<String>
    private let base = FixedASFDevice(id: "")

    var id: String { base.id }
    var model: String { base.model }
    var name: String { base.name }
    var platform: String { base.platform }
    var version: String { base.version }
    var thirdPartyId: String? { base.thirdPartyId }
    var height: String { base.height }
    var width: String { base.width }
    var locale: String { base.locale }
    var type: String { base.type }

    init(reads: Recorder<String>) {
        self.reads = reads
    }

    func deviceInfo() async -> String {
        await reads.record("deviceInfo")
        return await base.deviceInfo()
    }
}

private struct FixedAppInfo: ASFAppInfoBehavior {
    let name: String? = "com.example.app"
    let targetSDK = "150000"
    let version = "1.2-34"
}

/// A device that fails the test when any of its values is read.
private struct UnreadableDevice: ASFDeviceBehavior {
    var id: String { Self.read() }
    var model: String { Self.read() }
    var name: String { Self.read() }
    var platform: String { Self.read() }
    var version: String { Self.read() }
    var thirdPartyId: String? { Self.read() }
    var height: String { Self.read() }
    var width: String { Self.read() }
    var locale: String { Self.read() }
    var type: String { Self.read() }

    func deviceInfo() async -> String {
        Self.read()
    }

    private static func read() -> String {
        XCTFail("The device was read")
        return ""
    }
}

/// An app that fails the test when any of its values is read.
private struct UnreadableAppInfo: ASFAppInfoBehavior {
    var name: String? { read() }
    var targetSDK: String { read() }
    var version: String { read() }

    private func read() -> String {
        XCTFail("The app was read")
        return ""
    }
}
