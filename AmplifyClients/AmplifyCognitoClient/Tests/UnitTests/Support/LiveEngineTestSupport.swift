//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A live engine over scripted Cognito: the real state machines, the client's credential slot
/// and device records over an in-memory keychain, and `ScriptedUserPool` / `ScriptedIdentity` in place of the
/// SDK clients.
final class LiveEngineHarness: @unchecked Sendable {

    let cognito = ScriptedCognito()
    let keychain = TestKeychain()
    let configuration: AuthClientConfiguration
    /// The hosted UI's browser and token endpoint, when a test scripts them (`LiveEngineWebUITests`).
    let hostedUIPresenter: (any HostedUISessionBehavior)?
    let hostedUIURLSession: (@Sendable () -> URLSession)?

    init(
        configuration: AuthClientConfiguration = ClientFixtures.configuration,
        hostedUIPresenter: (any HostedUISessionBehavior)? = nil,
        hostedUIURLSession: (@Sendable () -> URLSession)? = nil
    ) {
        self.configuration = configuration
        self.hostedUIPresenter = hostedUIPresenter
        self.hostedUIURLSession = hostedUIURLSession
    }

    var namespace: SessionStorageNamespace {
        SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil)
    }

    /// The engine's resources: device records in this harness's keychain, analytics that never reads, the
    /// scripted services for the configured pools only, and a fixed device (`FixedDeviceASF`).
    func resources() throws -> EngineResources {
        let clients = try CognitoServiceClients(configuration: configuration, configureUserPoolClient: nil)
        return EngineResources(
            authConfiguration: AuthConfiguration(client: configuration),
            clients: clients,
            devices: DeviceRecordIO(store: keychain.deviceStore(for: namespace)),
            analytics: LazyUserPoolAnalytics(
                pinpointAppId: nil,
                keychain: keychain.itemStore(service: LazyUserPoolAnalytics.pinpointContextService)
            ),
            services: EngineServices(
                userPool: configuration.userPool == nil ? nil : ScriptedUserPool(cognito: cognito),
                identity: configuration.identityPool == nil ? nil : ScriptedIdentity(cognito: cognito)
            ),
            makeHostedUIPresenter: { [hostedUIPresenter] in hostedUIPresenter ?? HostedUIASWebAuthenticationSession() },
            makeHostedUIURLSession: hostedUIURLSession ?? EngineResources.makeURLSession,
            makeAdvancedSecurity: FixedDeviceASF.factory
        )
    }

    /// What the plugin's own credential store retrieves when `payload` is stored, as it is, under the
    /// plugin's session account for this configuration, `amplify.<pool namespace>.session`: the record the
    /// default session shares with the plugin. Runs over a keychain of its own.
    func retrievedByThePlugin(_ payload: Data) throws -> AmplifyCredentials {
        let itemStore = TestKeychain().itemStore(service: SessionRecordStore.unsharedService)
        try itemStore.set(payload, key: SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace))
        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: AuthConfiguration(client: configuration),
            keychain: itemStore,
            logger: DiscardingEngineLogger()
        )
        return try store.retrieveCredential()
    }

    func engine(
        onStepCancelled: (@Sendable (EngineOperation) -> Void)? = nil,
        whileStopping: (@Sendable () async -> Void)? = nil
    ) throws -> LiveSessionEngine {
        try LiveSessionEngine(resources: resources(), onStepCancelled: onStepCancelled, whileStopping: whileStopping)
    }

    // MARK: Scripts

    /// SRP: `InitiateAuth` answers `PASSWORD_VERIFIER`, and `RespondToAuthChallenge` answers `next`, tokens
    /// for `username` by default.
    func scriptSRP(
        _ username: String = "alice",
        version: Int = 1,
        then next: RespondToAuthChallengeOutput? = nil
    ) {
        cognito.once("InitiateAuth") { (_: InitiateAuthInput) in LiveEngineFixtures.passwordVerifier(username) }
        let answer = next ?? LiveEngineFixtures.signedIn(username, version: version)
        cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in answer }
    }

    /// The identity pool: `GetId` answers `identityId`, and `GetCredentialsForIdentity` answers AWS
    /// credentials for it.
    func scriptIdentityPool(identityId: String = LiveEngineFixtures.identityId, version: Int = 1) {
        cognito.always("GetId") { (_: GetIdInput) in GetIdOutput(identityId: identityId) }
        cognito.always("GetCredentialsForIdentity") { (input: GetCredentialsForIdentityInput) in
            GetCredentialsForIdentityOutput(
                credentials: LiveEngineFixtures.awsCredentials(version: version),
                identityId: input.identityId
            )
        }
    }

    /// `RevokeToken` and `GlobalSignOut` succeed.
    func scriptSignOut() {
        cognito.always("RevokeToken") { (_: RevokeTokenInput) in RevokeTokenOutput() }
        cognito.always("GlobalSignOut") { (_: GlobalSignOutInput) in GlobalSignOutOutput() }
    }

    /// `GetTokensFromRefreshToken` answers tokens one version on.
    func scriptRefresh(_ username: String = "alice", version: Int = 2) {
        cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) in
            GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens(username, version: version))
        }
    }

    /// Signs `username` in through SRP and the identity pool, and returns the payload.
    func signedInPayload(_ username: String = "alice", on engine: LiveSessionEngine) async throws -> Data {
        scriptSRP(username)
        scriptIdentityPool()
        guard case .done(let payload) = try await engine.signIn(.srp(username), current: nil) else {
            throw FixtureError(description: "the scripted sign-in did not finish")
        }
        return payload
    }
}

extension EngineSignInRequest {

    static func srp(_ username: String = "alice", password: String = "password") -> EngineSignInRequest {
        EngineSignInRequest(username: username, password: password, authFlowType: nil, clientMetadata: [:])
    }

    static func flow(
        _ flow: AuthClientAuthFlowType,
        _ username: String = "alice",
        password: String? = "password"
    ) -> EngineSignInRequest {
        EngineSignInRequest(username: username, password: password, authFlowType: flow, clientMetadata: [:])
    }
}

extension EngineConfirmSignInRequest {

    static func answer(
        _ response: String,
        attributes: [String: String] = [:],
        friendlyDeviceName: String? = nil
    ) -> EngineConfirmSignInRequest {
        EngineConfirmSignInRequest(
            challengeResponse: response,
            userAttributes: attributes,
            clientMetadata: [:],
            friendlyDeviceName: friendlyDeviceName
        )
    }
}

/// The operations a cancel stopped, as `LiveSessionEngine(onStepCancelled:)` reports them.
///
/// - Note: `@unchecked Sendable`: `operations` is only touched while holding `lock`.
final class StoppedOperations: @unchecked Sendable {
    private let lock = NSLock()
    private var operations: [EngineOperation] = []

    var all: [EngineOperation] {
        lock.lock()
        defer { lock.unlock() }
        return operations
    }

    func append(_ operation: EngineOperation) {
        lock.lock()
        operations.append(operation)
        lock.unlock()
    }
}

/// Cognito responses and tokens for the live engine tests.
enum LiveEngineFixtures {

    static let identityId = "us-east-1:identity-alice"

    /// A JWT the engine can read (it never checks signatures): `sub`, `username`, `cognito:username`, and an
    /// expiry an hour after `issuedAt` (far in the future by default).
    static func jwt(
        _ username: String,
        use: String,
        version: Int = 1,
        expiry: Date = Date(timeIntervalSince1970: 4_000_000_000)
    ) -> String {
        let header = #"{"alg":"none","typ":"JWT"}"#
        let claims = """
        {"sub":"sub-\(username)","username":"\(username)","cognito:username":"\(username)",\
        "token_use":"\(use)","v":\(version),"exp":\(Int(expiry.timeIntervalSince1970)),"iat":1700000000}
        """
        return "\(base64URL(header)).\(base64URL(claims)).signature"
    }

    static func base64URL(_ text: String) -> String {
        Data(text.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func tokens(
        _ username: String = "alice",
        version: Int = 1,
        refreshToken: String? = nil
    ) -> CognitoIdentityProviderClientTypes.AuthenticationResultType {
        CognitoIdentityProviderClientTypes.AuthenticationResultType(
            accessToken: jwt(username, use: "access", version: version),
            expiresIn: 3_600,
            idToken: jwt(username, use: "id", version: version),
            newDeviceMetadata: nil,
            refreshToken: refreshToken ?? "refresh-\(username)-v\(version)",
            tokenType: "Bearer"
        )
    }

    static func signedIn(_ username: String = "alice", version: Int = 1) -> RespondToAuthChallengeOutput {
        RespondToAuthChallengeOutput(authenticationResult: tokens(username, version: version), challengeParameters: [:])
    }

    static func challenge(
        _ name: CognitoIdentityProviderClientTypes.ChallengeNameType,
        parameters: [String: String] = [:],
        session: String = "challenge-session"
    ) -> RespondToAuthChallengeOutput {
        RespondToAuthChallengeOutput(challengeName: name, challengeParameters: parameters, session: session)
    }

    static func initiateChallenge(
        _ name: CognitoIdentityProviderClientTypes.ChallengeNameType,
        parameters: [String: String] = [:],
        session: String = "challenge-session"
    ) -> InitiateAuthOutput {
        InitiateAuthOutput(challengeName: name, challengeParameters: parameters, session: session)
    }

    static func awsCredentials(version: Int = 1) -> CognitoIdentityClientTypes.Credentials {
        CognitoIdentityClientTypes.Credentials(
            accessKeyId: "AKID-v\(version)",
            expiration: Date(timeIntervalSince1970: 4_000_000_000),
            secretKey: "secret-v\(version)",
            sessionToken: "session-v\(version)"
        )
    }

    static let smsParameters = [
        "CODE_DELIVERY_DELIVERY_MEDIUM": "SMS",
        "CODE_DELIVERY_DESTINATION": "+1******1234"
    ]

    /// A `PASSWORD_VERIFIER` challenge the engine's SRP arithmetic accepts, for `username`: the plugin's test
    /// values (`SRPTestData.swift`), copied, since the client's tests never import plugin test code. Cognito
    /// answers with the user's own `USERNAME` and `USER_ID_FOR_SRP`, so the fixture does too.
    static func passwordVerifier(_ username: String = "alice") -> InitiateAuthOutput {
        InitiateAuthOutput(
        challengeName: .passwordVerifier,
        challengeParameters: [
            "SALT": "79b00c90ebb6221ab4cad530f41441ed",
            "SECRET_BLOCK": "CDX6lsfSfPHwLUJpDSXIfkoLHEPmRc0e+g8riKvQzoqhA8UxgAKGQxx9NG5iKMpWtlRNqv" +
                "iaz0SOm3smLgVYrzwbkMYlrtqD2E1PO9/1GSQsV/Kqddum/p+y4CMFujQZE4TWH/VbxD0B" +
                "tZOfKL9M/dr1Pw7aOwxAlNKung5+KW3sFMdj7GNvU6MMNGXspx7u8d2L0de1GuAlF0YSxT" +
                "E5NOrrFuatU/rPRetJN5c/vvgBZr+5eoGVdYLuDL/8gk2QHgS/+SIR88OBbs1h5zb8GKnh" +
                "Qk/eib2PozCd96L/TTEGU0Lxg89UOnQ/HNQnNiKHBRym/1zUsNW0bjQex4K4y9Ap2tZJgO" +
                "Dy5yzNrpa21mMskYK5Ryv8zn+G36Otp2tdWwGxV8MkJPyW56LLY5Gbbr3T5xOSUavVAGgG" +
                "U/1ikV3V1BPITwikCpVZdxwnldNCBh98en60Uz+o9Q+k+/PtfbyhenfNCn61umTofEc78L" +
                "o6SL9WRmkTyabBrR+iX4YjGBAyxURLChdhnA+StCkGq+cDmgJuMO9rAV1BWh4fMCvykQww" +
                "6ZnFHHWkL3PSyPzfTiOIcnPT6QIb5jxDut/lZm5JJiyGi1FqjCjuhMrwKilwP92zm15WvG" +
                "y74LWMVtwa5Qy+KwZS1cvNULGL9QaOs+H+xbI1Hu+heLPPUsfAFZwOH2vDlkmRSD1B7cSx" +
                "tsY4Zb54j3+vrz1rT4EAWLZCwZ9OJhVPPK68llsH2NWKzKKbfvEdxwDNMXll2D1GCTkhvT" +
                "w7jmuzKD5k4vQyvmLduuhr4NpyaAzgmNfVIljhjjz7yJjiF8/JKuPHMLMrBV8kXeJqlDfh" +
                "qa/0sDKhkIdAcuGLPnUHiVWG5pdzyp0ELUwSwoS0p5HmOd8Mv/sXX/ZNqMDTTYm0G7IXrT" +
                "tKWWQAvMw2bVMFC5f4fSbSpIoVjbTChumqLqDrT0zeC6whXT1NWL1RDrIyWN5BQBH5hpF5" +
                "HPsxkPVEskQzeNjeFTvHA4sgSlbSVoSP8TnTkwwBxoLG6kH2JMn3ar5K2lCf2VSd+wcgzt" +
                "AIVgiSc6eDVZEnXThX2j2ZJObPwcN7d21R1l6+FgH7XA7kbBWUV/dVchXuflNa+K2/ubmO" +
                "/ofsasdw1+4JkJzjJVecX/KN/E79m1TDLzWSb1jnTrQpw5fCu+bAXtADzHdo7gynnek5gr" +
                "9jzfZfPZ1Niu6/IVmTN/ClBt/hbr42VUnDw0liYqXe0/2m4ah2t/w1PYIeCnFUtNU+19Pf" +
                "CzXnLOCwFwNNAj4JA7mX03nwvWKBMTjqv2Rx5h0dicuRZJKxjbzS/NrRjVTeaLJ+dg8iM0" +
                "zXGxVGVNcc7WfmpngTDxGQyxUWeOTx53CL543xIZpTlsuR50uHc0/epmg5WpCQsKMAAyO3" +
                "Fv2PRS378XaNMGNIyb7ZRuik+7IHbCNOB6B4Uqry3QJUg9dycsumcLqJw4Z3EvAuj5EMO6" +
                "FMA0Gre8GVhICluhCmkNwbfe/UfsBSGffohGMMDHO/4IVn1pGiNRix6aAhiRdTtRgeFHq4" +
                "fl/swCbhKecSbdzHlvCPjpfaidWI7ZYBALwTeWIDbFP21Rdk1BuU79bCwmuZ9No5y52oyA" +
                "bA7jMS0q3ld4sAAw8YfRNf0KggdA9Iolz9qdI/8xVLTLWsdvv1NA1JIPb8lPtlkqTlFYDp" +
                "inYbJk4W/1BOS85TSWPBwadRpVhEIDeH42hIgnvEPA==",
            "USER_ID_FOR_SRP": username,
            "SRP_B": srpB,
            "USERNAME": username
        ],
        session: "srp-session"
        )
    }

    private static let srpB = "b39ff004593719894a4d2d79146aa19be1e45992f44392fdf13dab2c4765ecefc8627f" +
        "2e7ac8f30f136116f848f9606119ee4cd7e2e617caa21cf7c53b2e9b07bda875cf10f6" +
        "9344c97916cd640b2a207bd54b28b2893c0f4d2273ecdc1f8bcd693f3d929e4038ae21" +
        "7d0a83daa5c782879558e0e9c66b7d1e851801f5190e5c226dd613c5234740039f9ed1" +
        "e732f2c4f57660025fd84275313f0b0a93642daeb2ab9f414a01fb973eaa9c9e940ff2" +
        "e5ffb56e03171d88969f93d57c30afdead8c5ac095d9c0a94ce04dba97404f993821cf" +
        "b7aa5b7e7d3461c4ef09462a3bdbc1002e3b9f2803a3dac11b2cbcb1353381ed35731a" +
        "13f60adadb6b33cf3d31a2b102c507265cede30e5bc84bb0b6ed1005c1cdc72cf87efa" +
        "96eec45283edfc75060a4bd0dc31544eb424cd25939626c014199ad433079b26a0ecab" +
        "129c2eef61d22994ad70c96d286e6e8c1abc65e7060ba69cb0d8c4a31cc08cc7d76ef9" +
        "2f757b2a34e7ae236aadbced9bb7a4a06e67da3a084833e0f3a0b903af0a74816031"
}

extension AmplifyCredentials {

    /// A payload decoded, for assertions.
    static func decoded(_ payload: Data) throws -> AmplifyCredentials {
        try CredentialSlot.decode(payload)
    }

    var signedInData: SignedInData? {
        switch self {
        case .userPoolOnly(let data), .userPoolAndIdentityPool(let data, _, _):
            return data
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            return nil
        }
    }

    var identityId: String? {
        switch self {
        case .userPoolAndIdentityPool(_, let identityId, _), .identityPoolOnly(let identityId, _),
             .identityPoolWithFederation(_, let identityId, _):
            return identityId
        case .userPoolOnly, .noCredentials:
            return nil
        }
    }
}

/// The last error of a throwing call, as `AuthClientError`, or `nil`.
func authError(_ error: Error) -> AuthClientError? {
    error as? AuthClientError
}
