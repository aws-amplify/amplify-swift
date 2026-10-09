//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import struct AWSCognitoIdentityProvider.StartWebAuthnRegistrationOutput
import struct AWSCognitoIdentityProvider.WebAuthnNotEnabledException
import XCTest
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// `associate`, in engine terms: the cases of the plugin's `AssociateWebAuthnCredentialTaskTests`, plus the
/// options-decoding failure, the second token request after the ceremony, and the caller's errors.
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the mocks' `@Sendable` closures.
///   `XCTestCase` is not `Sendable`, and each test runs alone.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class WebAuthnAssociateOperationTests: XCTestCase, @unchecked Sendable {
    private var fixture: WebAuthnOperationsFixture!
    private var registrant: MockCredentialRegistrant!
    private let startCalls = TestCounter()
    private let startTokens = TestBox<[String?]>([])
    private let completeInputs = TestBox<[[String?]]>([])
    private var identityProvider: MockIdentityProvider {
        get { fixture.identityProvider }
        set { fixture.identityProvider = newValue }
    }

    override func setUp() {
        fixture = WebAuthnOperationsFixture()
        startCalls.set(0)
        startTokens.set([])
        completeInputs.set([])
        registrant = MockCredentialRegistrant()
        registrant.mockedCreateResponse = .success(
            .init(credentialId: "credentialId", attestationObject: "attestationObject", clientDataJSON: "clientDataJSON")
        )
        let startCalls = startCalls
        let startTokens = startTokens
        identityProvider.mockStartWebAuthnRegistrationResponse = { input in
            startCalls.increment()
            startTokens.with { $0.append(input.accessToken) }
            return Self.startResponse()
        }
        let completeInputs = completeInputs
        identityProvider.mockCompleteWebAuthnRegistrationResponse = { input in
            var credentialId: String?
            do {
                credentialId = try input.credential?.asStringMap()["id"]?.asString()
            } catch {
                XCTFail("The completed credential is not a JSON object with an id: \(error)")
            }
            completeInputs.with { $0.append([input.accessToken, credentialId]) }
            return .init()
        }
    }

    override func tearDown() {
        registrant = nil
        fixture = nil
    }

    /// Associate, success
    ///
    /// - Given: Cognito starts and completes the registration, and the ceremony creates a credential
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - start, the ceremony and complete each run once
    ///    - the token and the user pool are asked for again after the ceremony, and complete sends the
    ///      second token and the created credential
    ///
    func testAssociate_withSuccess_startsCreatesAndCompletes() async throws {
        try await associate()

        XCTAssertEqual(startCalls.get(), 1)
        XCTAssertEqual(startTokens.get(), ["token-1"])
        XCTAssertEqual(registrant.createCallCount.get(), 1)
        XCTAssertEqual(completeInputs.get(), [["token-2", "credentialId"]])
        XCTAssertEqual(fixture.tokens.get(), ["token-1", "token-2"])
        XCTAssertEqual(fixture.userPoolCalls.get(), 2)
    }

    /// Associate, the ceremony fails
    ///
    /// - Given: the registrant throws `WebAuthnError.creationFailed(.failed)`
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - it throws that error's `EngineAuthError`, whose underlying error is the `ASAuthorizationError`
    ///    - complete is not called
    ///
    func testAssociate_withRegistrationFailed_throwsTheCeremonyError() async {
        let ceremonyError = WebAuthnError.creationFailed(error: ASAuthorizationError(.failed))
        registrant.mockedCreateResponse = .failure(ceremonyError)

        do {
            try await associate()
            XCTFail("Should have failed")
        } catch let error as EngineAuthError {
            XCTAssertEqual(error, ceremonyError.engineError)
            guard case .service(_, _, let underlyingError) = error else {
                return XCTFail("Expected EngineAuthError.service, got \(error)")
            }
            XCTAssertEqual((underlyingError as? ASAuthorizationError)?.code, .failed)
        } catch {
            XCTFail("Expected EngineAuthError, got \(error)")
        }
        XCTAssertEqual(startCalls.get(), 1)
        XCTAssertEqual(registrant.createCallCount.get(), 1)
        XCTAssertEqual(completeInputs.get().count, 0)
    }

    /// Associate, options that cannot be decoded
    ///
    /// - Given: `StartWebAuthnRegistration` answers without a challenge
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - it throws the associate unknown-service error, whose underlying error is the `WebAuthnCredentialError`
    ///    - the ceremony and complete are not run
    ///
    func testAssociate_withUndecodableOptions_throwsTheUnknownServiceError() async {
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            .init(credentialCreationOptions: ["rp": ["id": "relyingPartyId"]])
        }

        do {
            try await associate()
            XCTFail("Should have failed")
        } catch let error as EngineAuthError {
            guard case .service(let description, _, let underlyingError) = error else {
                return XCTFail("Expected EngineAuthError.service, got \(error)")
            }
            XCTAssertEqual(
                description,
                "An unknown error type was thrown by the service. Unable to associate WebAuthn credential."
            )
            XCTAssertTrue(
                underlyingError is WebAuthnCredentialError<CredentialCreationOptions>,
                "\(String(describing: underlyingError))"
            )
            XCTAssertTrue(
                underlyingError is AnyWebAuthnCredentialError,
                "\(String(describing: underlyingError))"
            )
        } catch {
            XCTFail("Expected EngineAuthError, got \(error)")
        }
        XCTAssertEqual(registrant.createCallCount.get(), 0)
        XCTAssertEqual(completeInputs.get().count, 0)
    }

    /// Associate, service error on start
    ///
    /// - Given: `StartWebAuthnRegistration` throws `WebAuthnNotEnabledException`
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - it throws `EngineAuthError.service` with the engine service code `webAuthnNotEnabled`
    ///    - the ceremony and complete are not run
    ///
    func testAssociate_withServiceErrorOnStart_throwsTheEngineServiceError() async {
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            throw WebAuthnNotEnabledException(message: "WebAuthn is not enabled")
        }

        await assertEngineServiceError(code: .webAuthnNotEnabled) { try await self.associate() }
        XCTAssertEqual(registrant.createCallCount.get(), 0)
        XCTAssertEqual(completeInputs.get().count, 0)
    }

    /// Associate, other error on start
    ///
    /// - Given: `StartWebAuthnRegistration` throws `CancellationError`
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - it throws `WebAuthnError.unknown`'s `EngineAuthError.service`, with the associate message
    ///    - the ceremony is not run
    ///
    func testAssociate_withOtherErrorOnStart_throwsTheUnknownServiceError() async {
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in throw CancellationError() }

        await assertUnknownServiceError(
            "An unknown error type was thrown by the service. Unable to associate WebAuthn credential."
        ) { try await self.associate() }
        XCTAssertEqual(registrant.createCallCount.get(), 0)
    }

    /// Associate, service error on complete
    ///
    /// - Given: `CompleteWebAuthnRegistration` throws `WebAuthnNotEnabledException`
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - it throws `EngineAuthError.service` with the engine service code `webAuthnNotEnabled`, after the ceremony
    ///
    func testAssociate_withServiceErrorOnComplete_throwsTheEngineServiceError() async {
        identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in
            throw WebAuthnNotEnabledException(message: "WebAuthn is not enabled")
        }

        await assertEngineServiceError(code: .webAuthnNotEnabled) { try await self.associate() }
        XCTAssertEqual(startCalls.get(), 1)
        XCTAssertEqual(registrant.createCallCount.get(), 1)
    }

    /// Associate, other error on complete
    ///
    /// - Given: `CompleteWebAuthnRegistration` throws `CancellationError`
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - it throws `WebAuthnError.unknown`'s `EngineAuthError.service`, with the associate message
    ///
    func testAssociate_withOtherErrorOnComplete_throwsTheUnknownServiceError() async {
        identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in throw CancellationError() }

        await assertUnknownServiceError(
            "An unknown error type was thrown by the service. Unable to associate WebAuthn credential."
        ) { try await self.associate() }
        XCTAssertEqual(registrant.createCallCount.get(), 1)
    }

    /// Associate, the caller's errors
    ///
    /// - Given: the access-token closure or the user-pool closure throws the caller's error, on its first call
    ///   (before start) or on its second (after the ceremony, before complete)
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - that error is rethrown unchanged
    ///    - a failure on the first call stops before start; one on the second, after the ceremony and before complete
    ///
    func testAssociate_callerErrorsPassThroughUnchanged() async {
        // The token closure, first call.
        await assertCallerError(.token) {
            try await WebAuthnCredentialOperations.associate(
                accessToken: { throw CallerOwnedError.token },
                userPool: self.fixture.userPool(),
                anchor: nil,
                ceremony: WebAuthnCredentialOperations.runCeremonyDirectly,
                registrant: self.registrantFactory
            )
        }
        assertCounts(start: 0, create: 0, complete: 0)

        // The token closure, second call.
        let tokenCalls = TestCounter()
        await assertCallerError(.token) {
            try await WebAuthnCredentialOperations.associate(
                accessToken: {
                    tokenCalls.increment()
                    if tokenCalls.get() == 2 { throw CallerOwnedError.token }
                    return "token"
                },
                userPool: self.fixture.userPool(),
                anchor: nil,
                ceremony: WebAuthnCredentialOperations.runCeremonyDirectly,
                registrant: self.registrantFactory
            )
        }
        assertCounts(start: 1, create: 1, complete: 0)

        // The user-pool closure, first call.
        await assertCallerError(.userPool) {
            try await WebAuthnCredentialOperations.associate(
                accessToken: self.fixture.accessToken(),
                userPool: { throw CallerOwnedError.userPool },
                anchor: nil,
                ceremony: WebAuthnCredentialOperations.runCeremonyDirectly,
                registrant: self.registrantFactory
            )
        }
        assertCounts(start: 1, create: 1, complete: 0)

        // The user-pool closure, second call.
        let userPoolCalls = TestCounter()
        let provider = identityProvider
        await assertCallerError(.userPool) {
            try await WebAuthnCredentialOperations.associate(
                accessToken: self.fixture.accessToken(),
                userPool: {
                    userPoolCalls.increment()
                    if userPoolCalls.get() == 2 { throw CallerOwnedError.userPool }
                    return provider
                },
                anchor: nil,
                ceremony: WebAuthnCredentialOperations.runCeremonyDirectly,
                registrant: self.registrantFactory
            )
        }
        assertCounts(start: 2, create: 2, complete: 0)
    }

    /// The marker for any `WebAuthnCredentialError`
    ///
    /// - Given: `WebAuthnCredentialError`s of three specialisations, and three other errors
    /// - When:
    ///    - each is checked with `is AnyWebAuthnCredentialError`
    /// - Then:
    ///    - every `WebAuthnCredentialError` matches, whatever its `T`; the others do not
    ///
    func testAnyWebAuthnCredentialError_matchesEverySpecialisationOnly() {
        let credentialErrors: [Error] = [
            WebAuthnCredentialError.missingValue("challenge", type: CredentialCreationOptions.self),
            WebAuthnCredentialError.decodingError(CancellationError(), type: CredentialAssertionOptions.self),
            WebAuthnCredentialError.missingValue("attestationObject", type: CredentialRegistrationPayload.self)
        ]
        let otherErrors: [Error] = [
            CancellationError(),
            WebAuthnError.unknown(message: "x", error: nil),
            ASAuthorizationError(.failed)
        ]

        for error in credentialErrors {
            XCTAssertTrue(error is AnyWebAuthnCredentialError, "\(error)")
        }
        for error in otherErrors {
            XCTAssertFalse(error is AnyWebAuthnCredentialError, "\(error)")
        }
    }

    /// The cumulative start, ceremony and complete counts since `setUp`.
    private func assertCounts(
        start: Int,
        create: Int,
        complete: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(startCalls.get(), start, "start", file: file, line: line)
        XCTAssertEqual(registrant.createCallCount.get(), create, "create", file: file, line: line)
        XCTAssertEqual(completeInputs.get().count, complete, "complete", file: file, line: line)
    }

    private func associate() async throws {
        try await WebAuthnCredentialOperations.associate(
            accessToken: fixture.accessToken(),
            userPool: fixture.userPool(),
            anchor: nil,
            ceremony: WebAuthnCredentialOperations.runCeremonyDirectly,
            registrant: registrantFactory
        )
    }

    /// Makes `registrant`, whatever the anchor.
    private var registrantFactory: WebAuthnCredentialOperations.RegistrantFactory {
        let registrant: MockCredentialRegistrant = registrant
        return { _ in registrant }
    }

    static func startResponse() -> StartWebAuthnRegistrationOutput {
        .init(credentialCreationOptions: [
            "challenge": "Y2hhbGxlbmdl",
            "rp": [
                "id": "relyingPartyId"
            ],
            "user": [
                "id": "dXNlcklk",
                "name": "User"
            ],
            "excludeCredentials": []
        ])
    }
}
#endif
